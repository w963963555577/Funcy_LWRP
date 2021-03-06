﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;
public class VertexRectToShader : BaseMeshEffect
{    
    public RectTransform targetGraphic;

    public Vector2 refBlur = new Vector2(0.9f, 0.1f);
    public List<RectTransform> parents = new List<RectTransform>();
    Vector2[] pTmp;
    protected override void Awake()
    {
        base.Awake();
    }
    protected override void OnEnable()
    {
        if (targetGraphic)
        {
            tmp1 = targetGraphic.anchoredPosition;
            tmp2 = targetGraphic.sizeDelta;
            tmp3 = refBlur;
        }        
    }
    Vector2 tmp1, tmp2, tmp3;
    Vector2 currentPosition;
    private void Update()
    {
        if (targetGraphic)
        {
            currentPosition = targetGraphic.anchoredPosition;
            foreach(var p in parents)
            {
                currentPosition += p.anchoredPosition;
            }
            if (tmp1 != currentPosition)
            {
                tmp1 = currentPosition;
                graphic.SetVerticesDirty();
            }
            if (tmp2 != targetGraphic.rect.size)
            {
                tmp2 = targetGraphic.rect.size;
                graphic.SetVerticesDirty();
            }
            if (tmp3 != refBlur)
            {
                tmp3 = refBlur;
                graphic.SetVerticesDirty();
            }
        }
    }
    public override void ModifyMesh(VertexHelper helper)
    {
        if (!IsActive() || helper.currentVertCount == 0 || !targetGraphic)
            return;                
        
        List<UIVertex> _vertexList = new List<UIVertex>();
        UIVertex vertex = new UIVertex();

        for (int i = 0; i < helper.currentVertCount; i++)
        {
            helper.PopulateUIVertex(ref vertex, i);
            vertex.uv1 = currentPosition;
            vertex.uv2 = targetGraphic.rect.size;
            vertex.uv3 = refBlur;
            helper.SetUIVertex(vertex, i);            
        }        
    }


    [System.Serializable]public class Vector3Event : UnityEvent<Vector3> { }
}
