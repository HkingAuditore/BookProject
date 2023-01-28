using UnityEngine;
[ExecuteInEditMode]
public class CustomCamera : MonoBehaviour
{
    public Camera        DepthCamera;
    public Material      DepthMat;
    public Material      BlendMat;
    public RenderTexture TraceRT;
    void Start()
    {
        DepthCamera.depthTextureMode = DepthTextureMode.Depth;
        TraceRT.Release();
    }
    
    void OnRenderImage (RenderTexture source, RenderTexture destination) {
        Graphics.Blit(source,destination,DepthMat);
        Graphics.Blit(destination,TraceRT,BlendMat);
    }
}
