using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraDepth : MonoBehaviour
{
    public Material material;
    private void OnEnable()
    {
        // 要获取摄像机的深度＋法线纹理
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }
    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Copy the source Render Texture to the destination,
        // applying the material along the way.
        Graphics.Blit(source, destination, material);
    }
}
