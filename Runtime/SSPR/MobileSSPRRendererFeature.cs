//see README here: https://github.com/ColinLeung-NiloCat/UnityURP-MobileScreenSpacePlanarReflection

using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
namespace UnityEngine.Funcy.LWRP.Runtime
{
    public class MobileSSPRRendererFeature : ScriptableRendererFeature
    {
        public static MobileSSPRRendererFeature instance; //for example scene to call, user should add 1 and not more than 1 MobileSSPRRendererFeature anyway

        [System.Serializable]
        public class PassSettings
        {
            [Header("Settings")]
            public bool shouldRenderSSPR = true;
            public float horizontalReflectionPlaneHeightWS = 0.01f; //default higher than ground a bit, to avoid ZFighting if user placed a ground plane at y=0
            [Range(0.01f, 1f)]
            public float fadeOutScreenBorderWidth = 0.5f;

            [Header("General Performance Settings")]
            [Range(128, 1024)]
            [Tooltip("set to 512 is enough for sharp reflection")]
            public int RT_height = 512;
            public bool ApplyFillHoleFix = true;

            [Header("Non-Vulkan performance Setting")]
            [Range(0, 4)]
            [Tooltip("set to 2 can reduce most of UAV flicking")]
            public int swapIteration = 2;

            [Header("Resources")]
            public ComputeShader SSPR_computeShader;
        }
        public PassSettings Settings = new PassSettings();

        public class CustomRenderPass : ScriptableRenderPass
        {
            static readonly int _SSPR_ColorRT_pid = Shader.PropertyToID("_MobileSSPR_ColorRT");
            static readonly int _SSPR_PackedDataRT_pid = Shader.PropertyToID("_MobileSSPR_PackedDataRT");
            static readonly int _SSPR_PosWSyRT_pid = Shader.PropertyToID("_MobileSSPR_PosWSyRT");
            RenderTargetIdentifier _SSPR_ColorRT_rti = new RenderTargetIdentifier(_SSPR_ColorRT_pid);
            RenderTargetIdentifier _SSPR_PackedDataRT_rti = new RenderTargetIdentifier(_SSPR_PackedDataRT_pid);
            RenderTargetIdentifier _SSPR_PosWSyRT_rti = new RenderTargetIdentifier(_SSPR_PosWSyRT_pid);


            ShaderTagId lightMode_SSPR_sti = new ShaderTagId("UniversalForward");//reflection plane renderer's material's shader must use this LightMode

            const int SHADER_NUMTHREAD_X = 8; //must match compute shader's [numthread(x)]
            const int SHADER_NUMTHREAD_Y = 8; //must match compute shader's [numthread(y)]

            PassSettings settings;

            public CustomRenderPass(PassSettings settings)
            {
                this.settings = settings;
            }

            int GetRTHeight()
            {
                return Mathf.CeilToInt(settings.RT_height / (float)SHADER_NUMTHREAD_Y) * SHADER_NUMTHREAD_Y;
            }
            int GetRTWidth()
            {
                float aspect = (float)Screen.width / Screen.height;
                return Mathf.CeilToInt(GetRTHeight() * aspect / (float)SHADER_NUMTHREAD_X) * SHADER_NUMTHREAD_X;
            }

            bool ShouldUseVulkanFastPath()
            {
                return SystemInfo.graphicsDeviceType == GraphicsDeviceType.Vulkan;
            }
            // This method is called before executing the render pass.
            // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
            // When empty this render pass will render to the active camera render target.
            // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
            // The render pipeline will ensure target setup and clearing happens in an performance manner.
            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                RenderTextureDescriptor rtd = new RenderTextureDescriptor(GetRTWidth(), GetRTHeight(), RenderTextureFormat.Default, 0, 0);

                rtd.sRGB = false; //don't need gamma correction when sampling these RTs, it is linear data already because it will be filled by screen's linear data
                rtd.enableRandomWrite = true; //using RWTexture2D in compute shader need to turn on this

                //color RT
                rtd.colorFormat = RenderTextureFormat.ARGB32; //we need alpha! (LDR is enough, ignore HDR is acceptable for reflection)
                cmd.GetTemporaryRT(_SSPR_ColorRT_pid, rtd);

                //PackedData RT
                if (ShouldUseVulkanFastPath())
                {
                    //posWSy RT (will use this RT for posWSy compare test, just like the concept of regular depth buffer)
                    rtd.colorFormat = RenderTextureFormat.RFloat;
                    cmd.GetTemporaryRT(_SSPR_PosWSyRT_pid, rtd);
                }
                else
                {
                    rtd.colorFormat = RenderTextureFormat.ARGBHalf; //half instead of float will help mobile to cut down render cost(bandwidth cost/2)
                    cmd.GetTemporaryRT(_SSPR_PackedDataRT_pid, rtd);
                }
            }

            // Here you can implement the rendering logic.
            // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
            // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
            // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cb = CommandBufferPool.Get("SSPR");

                int dispatchThreadGroupXCount = GetRTWidth() / SHADER_NUMTHREAD_X; //divide by shader's numthreads.x
                int dispatchThreadGroupYCount = GetRTHeight() / SHADER_NUMTHREAD_Y; //divide by shader's numthreads.y
                int dispatchThreadGroupZCount = 1; //divide by shader's numthreads.z

                if (settings.shouldRenderSSPR)
                {
                    cb.SetComputeVectorParam(settings.SSPR_computeShader, Shader.PropertyToID("_RTSize"), new Vector2(GetRTWidth(), GetRTHeight()));
                    cb.SetComputeFloatParam(settings.SSPR_computeShader, Shader.PropertyToID("_HorizontalPlaneHeightWS"), settings.horizontalReflectionPlaneHeightWS);
                    cb.SetComputeFloatParam(settings.SSPR_computeShader, Shader.PropertyToID("_FadeOutScreenBorderWidth"), settings.fadeOutScreenBorderWidth);

                    if (!ShouldUseVulkanFastPath())
                    {
                        //draw RT (kernel #0) 
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 0, "ColorRT", _SSPR_ColorRT_rti);
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 0, "PackedDataRT", _SSPR_PackedDataRT_rti);
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 0, "_CameraOpaqueTexture", new RenderTargetIdentifier("_CameraOpaqueTexture"));
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 0, "_CameraDepthTexture", new RenderTargetIdentifier("_CameraDepthTexture"));
                        cb.DispatchCompute(settings.SSPR_computeShader, 0, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);

                        //double swap to reduce 90% of the UAV flickering(kernel #1)
                        //run exactly 2 iterations, running >2 iterations will not improve result much
                        for (int i = 0; i < settings.swapIteration; i++)
                        {
                            cb.SetComputeTextureParam(settings.SSPR_computeShader, 1, "PackedDataRT", _SSPR_PackedDataRT_rti);
                            cb.DispatchCompute(settings.SSPR_computeShader, 1, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);
                        }

                        //resolve to ColorRT (kernel #2)
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 2, "ColorRT", _SSPR_ColorRT_rti);
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 2, "PackedDataRT", _SSPR_PackedDataRT_rti);
                        cb.DispatchCompute(settings.SSPR_computeShader, 2, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);
                    }
                    else
                    {
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 4, "ColorRT", _SSPR_ColorRT_rti);
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 4, "PosWSyRT", _SSPR_PosWSyRT_rti);

                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 4, "_CameraOpaqueTexture", new RenderTargetIdentifier("_CameraOpaqueTexture"));
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 4, "_CameraDepthTexture", new RenderTargetIdentifier("_CameraDepthTexture"));
                        cb.DispatchCompute(settings.SSPR_computeShader, 4, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);
                    }

                    //shared pass: fill RT hole (kernel #3),at least run once
                    if (settings.ApplyFillHoleFix)
                    {
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 3, "ColorRT", _SSPR_ColorRT_rti);
                        cb.SetComputeTextureParam(settings.SSPR_computeShader, 3, "PackedDataRT", _SSPR_PackedDataRT_rti);
                        cb.DispatchCompute(settings.SSPR_computeShader, 3, Mathf.CeilToInt(dispatchThreadGroupXCount / 2f), Mathf.CeilToInt(dispatchThreadGroupYCount / 2f), dispatchThreadGroupZCount);
                    }

                    //send out to global, for user's shader to sample  reflection result RT (_MobileSSPR_ColorRT)
                    //where _MobileSSPR_ColorRT's rgb is reflection color, a is reflection usage 0~1 for lerp with fallback reflection probe's rgb
                    cb.SetGlobalTexture(_SSPR_ColorRT_pid, _SSPR_ColorRT_rti);
                    cb.EnableShaderKeyword("_MobileSSPR");
                }
                else
                {
                    //allow user to skip SSPR related code if disabled
                    cb.DisableShaderKeyword("_MobileSSPR");
                }

                context.ExecuteCommandBuffer(cb);
                CommandBufferPool.Release(cb);

                //======================================================================
                
                //draw objects(e.g. reflective wet ground plane) with lightmode "MobileSSPR", which will sample _MobileSSPR_ColorRT
                DrawingSettings drawingSettings = CreateDrawingSettings(lightMode_SSPR_sti, ref renderingData, SortingCriteria.CommonOpaque);
                FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.all);
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);
                
            }

            /// Cleanup any allocated resources that were created during the execution of this render pass.
            public override void FrameCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(_SSPR_ColorRT_pid);

                if (ShouldUseVulkanFastPath())
                    cmd.ReleaseTemporaryRT(_SSPR_PosWSyRT_pid);
                else
                    cmd.ReleaseTemporaryRT(_SSPR_PackedDataRT_pid);
            }
        }

        CustomRenderPass m_ScriptablePass;

        public override void Create()
        {
            //we can't run without the correct compute shader, early exit if compute shader is null
            if (!Settings.SSPR_computeShader)
            {
                Debug.LogWarning("You must assign MobileSSPRComputeShader to SSPR_computeShader slot! Abort SSPR rendering.");
                return;
            }

            instance = this;

            m_ScriptablePass = new CustomRenderPass(Settings);

            // Configures where the render pass should be injected.
            m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;//we must wait _CameraOpaqueTexture & _CameraDepthTexture is usable
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (!Settings.SSPR_computeShader) return;

            renderer.EnqueuePass(m_ScriptablePass);
        }
    }
}