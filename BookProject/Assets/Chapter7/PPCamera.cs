using UnityEngine;
[ExecuteInEditMode]
public class PPCamera : MonoBehaviour
{
    public Material Mat;
    void OnRenderImage (RenderTexture source, RenderTexture destination) {
        Graphics.Blit(source,destination,Mat);
    }
}
