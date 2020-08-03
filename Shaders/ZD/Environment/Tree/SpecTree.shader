Shader "ZDShader/LWRP/Environment/SpecialTree"
{
    Properties
    {
        [HideInInspector] _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _AlphaCutoff ("Alpha Cutoff ", Range(0, 1)) = 0.5
        _BaseMap ("BaseMap", 2D) = "white" { }
        _ClipThreshod ("ClipThreshod", Range(0, 1)) = 0.4
        _LambertOffset ("LambertOffset", Float) = 0.5
        [HDR]_BlendColor_Light ("BlendColor_Light", Color) = (0.227451, 0.8784314, 0.4121743, 0)
        [HDR]_BlendColor_Mid ("BlendColor_Mid", Color) = (0.03555536, 0.4433962, 0.1661608, 0)
        [HDR]_BlendColor_Dark ("BlendColor_Dark", Color) = (0, 0.254717, 0.1783019, 0)
        [HDR]_BlendColor_SelfShadow ("BlendColor_SelfShadow", Color) = (0, 0.1776338, 0.2, 0)
        [HDR]_SpecColor ("SpecColor", Color) = (0.227451, 1.498039, 0, 1)
        _SpecularOffset ("SpecularOffset", Float) = 0.44
        _Speed ("Speed", Float) = 1.5
        _Amount ("Amount", Float) = 5
        _Distance ("Distance", Range(0, 1)) = 0.5
        _ZMotion ("ZMotion", Range(0, 1)) = 0.5
        _ZMotionSpeed ("ZMotionSpeed", Range(0, 20)) = 10
        _OriginWeight ("OriginWeight", Range(0, 1)) = 0.5
        _PositionMask ("PositionMask", 2D) = "white" { }
        [HideInInspector] _texcoord ("", 2D) = "white" { }
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }
        
        Cull Off
        
        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }
            
            Blend One Zero, One Zero
            ZWrite On
            ZTest LEqual
            Offset 0, 0
            ColorMask RGBA
            
            HLSLPROGRAM
            
            #pragma multi_compile_instancing
            #pragma multi_compile_fog



            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _DrawMeshInstancedProcedural

            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct VertexInput
            {
                float4 vertex: POSITION;
                float3 ase_normal: NORMAL;
                float4 ase_texcoord: TEXCOORD0;

                #ifdef _DrawMeshInstancedProcedural
                    uint mid: SV_INSTANCEID;
                #else
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                #endif
            };

            struct VertexOutput
            {
                float4 clipPos: SV_POSITION;
                float3 worldPos: TEXCOORD0;
                float4 shadowCoord: TEXCOORD1;
                float fogFactor: TEXCOORD2;
                float4 ase_texcoord3: TEXCOORD3;
                float4 ase_texcoord4: TEXCOORD4;
                
                #ifdef _DrawMeshInstancedProcedural
                #else
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    UNITY_VERTEX_OUTPUT_STEREO
                #endif
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _PositionMask_ST;
            float4 _BaseMap_ST;
            float4 _BlendColor_SelfShadow;
            float4 _BlendColor_Dark;
            float4 _BlendColor_Mid;
            float4 _BlendColor_Light;
            float4 _SpecColor;
            float _Speed;
            float _Amount;
            float _Distance;
            float _OriginWeight;
            float _ZMotionSpeed;
            float _ZMotion;
            float _LambertOffset;
            float _ClipThreshod;
            float _SpecularOffset;
            #ifdef _DrawMeshInstancedProcedural
                StructuredBuffer<float4x4> _ObjectToWorldBuffer;
                StructuredBuffer<float4x4> _WorldToObjectBuffer;
                StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            #endif
            CBUFFER_END
            TEXTURE2D(_PositionMask);            SAMPLER(sampler_PositionMask);
            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);


            
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                #ifdef _DrawMeshInstancedProcedural
                    uint id = _VisibleInstanceOnlyTransformIDBuffer[v.mid];
                #else
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_TRANSFER_INSTANCE_ID(v, o);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                #endif

                float2 appendResult182 = (float2(v.vertex.xyz.xy));
                float temp_output_107_0 = (v.vertex.xyz.y * _Amount);
                float4 transform95 = float4(0, 0, 0, 1);
                #ifdef _DrawMeshInstancedProcedural
                    transform95 = mul(_ObjectToWorldBuffer[id], float4(0, 0, 0, 1));
                #else
                    transform95 = mul(GetObjectToWorldMatrix(), float4(0, 0, 0, 1));
                #endif
                float lerpResult126 = lerp((sin(((0.0 * _Speed) + temp_output_107_0)) * _Distance), (sin(((0.0 * _Speed) + temp_output_107_0)) * _Distance * (distance(v.vertex.xyz.y, transform95.y) / 3.0)), _OriginWeight);
                float temp_output_125_0 = (sin(((temp_output_107_0 * (_ZMotionSpeed / 10.0)) + (_TimeParameters.x * (_Speed / 10.0) * _ZMotionSpeed))) * _ZMotion);
                float3 appendResult132 = (float3(0.0, 0.0, (lerpResult126 * temp_output_125_0)));

                float3 ase_objectScale = float3(0, 0, 0);
                #ifdef _DrawMeshInstancedProcedural
                    ase_objectScale = float3(length(_ObjectToWorldBuffer[id][ 0 ].xyz), length(_ObjectToWorldBuffer[id][ 1 ].xyz), length(_ObjectToWorldBuffer[id][ 2 ].xyz));
                #else
                    ase_objectScale = float3(length(GetObjectToWorldMatrix()[ 0 ].xyz), length(GetObjectToWorldMatrix()[ 1 ].xyz), length(GetObjectToWorldMatrix()[ 2 ].xyz));
                #endif
                

                
                float3 ase_worldNormal = float3(0.0, 0.0, 0.0);
                #ifdef _DrawMeshInstancedProcedural
                    #ifdef UNITY_ASSUME_UNIFORM_SCALING
                        ase_worldNormal = SafeNormalize(mul((real3x3)_ObjectToWorldBuffer[id], v.ase_normal));
                    #else
                        ase_worldNormal = SafeNormalize(mul(v.ase_normal, (real3x3)_WorldToObjectBuffer[id]));
                    #endif
                #else
                    ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
                #endif

                o.ase_texcoord4.xyz = ase_worldNormal;
                
                o.ase_texcoord3.xy = v.ase_texcoord.xy;
                
                //setting value to unused interpolator channels and avoid initialization warnings
                o.ase_texcoord3.zw = 0;
                o.ase_texcoord4.w = 0;

                float3 vertexValue = SAMPLE_TEXTURE2D_LOD(_PositionMask, sampler_PositionMask, ((appendResult182 * _PositionMask_ST.xy) + _PositionMask_ST.zw), unity_LODFade).r * appendResult132 / ase_objectScale;

                v.vertex.xyz += vertexValue;

                v.ase_normal = v.ase_normal;
                
                float3 positionWS = float3(0.0, 0.0, 0.0);
                
                #ifdef _DrawMeshInstancedProcedural
                    positionWS = mul(_ObjectToWorldBuffer[id], float4(v.vertex.xyz, 1.0)).xyz;
                #else
                    positionWS = TransformObjectToWorld(v.vertex.xyz);
                #endif

                float4 positionCS = TransformWorldToHClip(positionWS);


                o.worldPos = positionWS;
                
                VertexPositionInputs vertexInput = (VertexPositionInputs)0;
                vertexInput.positionWS = positionWS;
                vertexInput.positionCS = positionCS;
                o.shadowCoord = GetShadowCoord(vertexInput);
                
                o.fogFactor = ComputeFogFactor(positionCS.z);
                
                o.clipPos = positionCS;
                return o;
            }

            half4 frag(VertexOutput IN): SV_Target
            {
                #ifdef _DrawMeshInstancedProcedural
                #else
                    UNITY_SETUP_INSTANCE_ID(IN);
                    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
                #endif
                
                float3 WorldPosition = IN.worldPos;
                
                float4 ShadowCoords = TransformWorldToShadowCoord(WorldPosition);
                
                float2 uv_BaseMap = IN.ase_texcoord3.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
                float4 tex2DNode5 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv_BaseMap);
                float3 ase_worldNormal = IN.ase_texcoord4.xyz;
                float dotResult41 = dot(ase_worldNormal, _MainLightPosition.xyz);
                float temp_output_47_0 = saturate((dotResult41 + _LambertOffset));
                float smoothstepResult82 = smoothstep(0.0, 0.5, temp_output_47_0);
                float4 lerpResult83 = lerp(_BlendColor_Dark, _BlendColor_Mid, smoothstepResult82);
                float smoothstepResult80 = smoothstep(0.5, 1.0, temp_output_47_0);
                float4 lerpResult57 = lerp(lerpResult83, _BlendColor_Light, smoothstepResult80);
                float ase_lightAtten = 0;
                Light ase_lightAtten_mainLight = GetMainLight(ShadowCoords);
                ase_lightAtten = ase_lightAtten_mainLight.distanceAttenuation * ase_lightAtten_mainLight.shadowAttenuation;
                float temp_output_147_0 = saturate((ase_lightAtten + temp_output_47_0));
                float4 lerpResult145 = lerp(_BlendColor_SelfShadow, lerpResult57, temp_output_147_0);
                float temp_output_3_0_g5 = (tex2DNode5.a - _ClipThreshod);
                float temp_output_3_0_g4 = (tex2DNode5.a - saturate((1.5 * _ClipThreshod)));
                float temp_output_200_0 = saturate((dotResult41 + (_SpecularOffset * - 1.0)));
                
                clip(tex2DNode5.a - _ClipThreshod);
                
                float3 BakedAlbedo = 0;
                float3 BakedEmission = 0;
                float3 Color = saturate(((tex2DNode5 * lerpResult145) + (saturate(((saturate((temp_output_3_0_g5 / fwidth(temp_output_3_0_g5))) - saturate((temp_output_3_0_g4 / fwidth(temp_output_3_0_g4)))) * temp_output_200_0 * temp_output_147_0 * tex2DNode5.a)) * _SpecColor))).rgb;
                float Alpha = 1.0;
                float AlphaClipThreshold = 0.5;

                
                //clip(Alpha - AlphaClipThreshold);
                
                //LODDitheringTransition(IN.clipPos.xyz, unity_LODFade.x);
                
                Color = MixFog(Color, IN.fogFactor);
                
                return half4(Color, Alpha);
            }
            
            ENDHLSL
            
        }

        // Used for rendering shadowmaps
        // Used for rendering shadowmaps
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            Cull[_Cull]
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ _DrawMeshInstancedProcedural
            
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            
            //#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _PositionMask_ST;
            float4 _BaseMap_ST;
            float4 _BlendColor_SelfShadow;
            float4 _BlendColor_Dark;
            float4 _BlendColor_Mid;
            float4 _BlendColor_Light;
            float4 _SpecColor;
            float _Speed;
            float _Amount;
            float _Distance;
            float _OriginWeight;
            float _ZMotionSpeed;
            float _ZMotion;
            float _LambertOffset;
            float _ClipThreshod;
            float _SpecularOffset;
            #ifdef _DrawMeshInstancedProcedural
                StructuredBuffer<float4x4> _ObjectToWorldBuffer;
                StructuredBuffer<float4x4> _WorldToObjectBuffer;
                StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            #endif
            CBUFFER_END
            TEXTURE2D(_PositionMask);            SAMPLER(sampler_PositionMask);
            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            float3 _LightDirection;
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
                float2 texcoord: TEXCOORD0;
                #ifdef _DrawMeshInstancedProcedural
                    uint mid: SV_INSTANCEID;
                #else
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                #endif
            };
            
            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                #ifdef _DrawMeshInstancedProcedural
                #else
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    UNITY_VERTEX_OUTPUT_STEREO
                #endif
            };
            
            float4 GetShadowPositionHClip(Attributes input)
            {
                #ifdef _DrawMeshInstancedProcedural
                    uint id = _VisibleInstanceOnlyTransformIDBuffer[input.mid];
                    
                    float3 positionWS = mul(_ObjectToWorldBuffer[id], float4(input.positionOS.xyz, 1.0)).xyz;
                    float3 normalWS = float3(0, 0, 0);
                    
                    #ifdef UNITY_ASSUME_UNIFORM_SCALING
                        normalWS = SafeNormalize(mul((real3x3)_ObjectToWorldBuffer[id], input.normalOS));
                    #else
                        normalWS = SafeNormalize(mul(input.normalOS, (real3x3)_WorldToObjectBuffer[id]));
                    #endif
                #else
                    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                    
                #endif
                
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE * 10);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE * 10);
                #endif
                
                return positionCS;
            }
            
            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                #ifdef _DrawMeshInstancedProcedural
                    uint id = _VisibleInstanceOnlyTransformIDBuffer[input.mid];
                #else
                    UNITY_SETUP_INSTANCE_ID(input);
                #endif

                float2 appendResult182 = (float2(input.positionOS.xyz.xy));
                float temp_output_107_0 = (input.positionOS.xyz.y * _Amount);
                float4 transform95 = float4(0, 0, 0, 1);
                #ifdef _DrawMeshInstancedProcedural
                    transform95 = mul(_ObjectToWorldBuffer[id], float4(0, 0, 0, 1));
                #else
                    transform95 = mul(GetObjectToWorldMatrix(), float4(0, 0, 0, 1));
                #endif
                float lerpResult126 = lerp((sin(((0.0 * _Speed) + temp_output_107_0)) * _Distance), (sin(((0.0 * _Speed) + temp_output_107_0)) * _Distance * (distance(input.positionOS.xyz.y, transform95.y) / 3.0)), _OriginWeight);
                float temp_output_125_0 = (sin(((temp_output_107_0 * (_ZMotionSpeed / 10.0)) + (_TimeParameters.x * (_Speed / 10.0) * _ZMotionSpeed))) * _ZMotion);
                float3 appendResult132 = (float3(0.0, 0.0, (lerpResult126 * temp_output_125_0)));

                float3 ase_objectScale = float3(0, 0, 0);
                #ifdef _DrawMeshInstancedProcedural
                    ase_objectScale = float3(length(_ObjectToWorldBuffer[id][ 0 ].xyz), length(_ObjectToWorldBuffer[id][ 1 ].xyz), length(_ObjectToWorldBuffer[id][ 2 ].xyz));
                #else
                    ase_objectScale = float3(length(GetObjectToWorldMatrix()[ 0 ].xyz), length(GetObjectToWorldMatrix()[ 1 ].xyz), length(GetObjectToWorldMatrix()[ 2 ].xyz));
                #endif
                
                float3 vertexValue = SAMPLE_TEXTURE2D_LOD(_PositionMask, sampler_PositionMask, ((appendResult182 * _PositionMask_ST.xy) + _PositionMask_ST.zw), unity_LODFade).r * appendResult132 / ase_objectScale;
                input.positionOS.xyz += vertexValue;

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }
            
            half Alpha(half albedoAlpha, half cutoff)
            {
                half alpha = albedoAlpha ;
                clip(alpha - cutoff);
                return alpha;
            }

            half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
            {
                return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
            }


            half4 ShadowPassFragment(Varyings input): SV_TARGET
            {
                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _ClipThreshod);
                return 0;
            }
            
            
            ENDHLSL
            
        }
        
        
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            
            ZWrite On
            ColorMask 0
            Cull[_Cull]
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ _DrawMeshInstancedProcedural
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            
            
            CBUFFER_START(UnityPerMaterial)
            float4 _PositionMask_ST;
            float4 _BaseMap_ST;
            float4 _BlendColor_SelfShadow;
            float4 _BlendColor_Dark;
            float4 _BlendColor_Mid;
            float4 _BlendColor_Light;
            float4 _SpecColor;
            float _Speed;
            float _Amount;
            float _Distance;
            float _OriginWeight;
            float _ZMotionSpeed;
            float _ZMotion;
            float _LambertOffset;
            float _ClipThreshod;
            float _SpecularOffset;
            #ifdef _DrawMeshInstancedProcedural
                StructuredBuffer<float4x4> _ObjectToWorldBuffer;
                StructuredBuffer<float4x4> _WorldToObjectBuffer;
                StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            #endif
            CBUFFER_END
            TEXTURE2D(_PositionMask);            SAMPLER(sampler_PositionMask);
            TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);

            struct Attributes
            {
                float4 position: POSITION;
                float2 texcoord: TEXCOORD0;
                #ifdef _DrawMeshInstancedProcedural
                    uint mid: SV_INSTANCEID;
                #else
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                #endif
            };
            
            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                
                #ifdef _DrawMeshInstancedProcedural
                #else
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    UNITY_VERTEX_OUTPUT_STEREO
                #endif
            };
            
            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                #ifdef _DrawMeshInstancedProcedural
                    uint id = _VisibleInstanceOnlyTransformIDBuffer[input.mid];
                #else
                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                #endif

                
                float2 appendResult182 = (float2(input.position.xyz.xy));
                float temp_output_107_0 = (input.position.xyz.y * _Amount);
                float4 transform95 = float4(0, 0, 0, 1);
                #ifdef _DrawMeshInstancedProcedural
                    transform95 = mul(_ObjectToWorldBuffer[id], float4(0, 0, 0, 1));
                #else
                    transform95 = mul(GetObjectToWorldMatrix(), float4(0, 0, 0, 1));
                #endif
                float lerpResult126 = lerp((sin(((0.0 * _Speed) + temp_output_107_0)) * _Distance), (sin(((0.0 * _Speed) + temp_output_107_0)) * _Distance * (distance(input.position.xyz.y, transform95.y) / 3.0)), _OriginWeight);
                float temp_output_125_0 = (sin(((temp_output_107_0 * (_ZMotionSpeed / 10.0)) + (_TimeParameters.x * (_Speed / 10.0) * _ZMotionSpeed))) * _ZMotion);
                float3 appendResult132 = (float3(0.0, 0.0, (lerpResult126 * temp_output_125_0)));

                float3 ase_objectScale = float3(0, 0, 0);
                #ifdef _DrawMeshInstancedProcedural
                    ase_objectScale = float3(length(_ObjectToWorldBuffer[id][ 0 ].xyz), length(_ObjectToWorldBuffer[id][ 1 ].xyz), length(_ObjectToWorldBuffer[id][ 2 ].xyz));
                #else
                    ase_objectScale = float3(length(GetObjectToWorldMatrix()[ 0 ].xyz), length(GetObjectToWorldMatrix()[ 1 ].xyz), length(GetObjectToWorldMatrix()[ 2 ].xyz));
                #endif
                
                float3 vertexValue = SAMPLE_TEXTURE2D_LOD(_PositionMask, sampler_PositionMask, ((appendResult182 * _PositionMask_ST.xy) + _PositionMask_ST.zw), unity_LODFade).r * appendResult132 / ase_objectScale;
                input.position.xyz += vertexValue;
                
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                
                float3 positionWS = float3(0.0, 0.0, 0.0);
                #ifdef _DrawMeshInstancedProcedural
                    positionWS = mul(_ObjectToWorldBuffer[id], float4(input.position.xyz, 1.0)).xyz;
                #else
                    positionWS = TransformObjectToWorld(input.position.xyz);
                #endif
                
                output.positionCS = TransformWorldToHClip(positionWS);
                return output;
            }
            
            half Alpha(half albedoAlpha, half cutoff)
            {
                half alpha = albedoAlpha;
                clip(alpha - cutoff);
                return alpha;
            }

            half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
            {
                return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
            }


            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _ClipThreshod);
                return 0;
            }
            
            
            ENDHLSL
            
        }
        UsePass "Universal Render Pipeline/Lit/Meta"
    }
}