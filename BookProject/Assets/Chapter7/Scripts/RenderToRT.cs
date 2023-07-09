using UnityEngine;

[ExecuteInEditMode]
public class RenderToRT : MonoBehaviour
{

    // 最终合成的Render Texture，包括当前轨迹和历史轨迹
    public RenderTexture FinalRT;
    // 临时Render Texture
    // 在下面的代码中，我们把它作为StepMat的_MainTex使用
    public RenderTexture TmpRT;
    // “笔刷”材质
    public Material StepMat;

    // 场景开始运行时调用
    private void Start()
    {
        // 清空FinalRT
        FinalRT.Release();
    }

    void Update()
    {
        StepMat.SetVector("_BrushPos", transform.position);
        Graphics.Blit(TmpRT, FinalRT, StepMat);
    }
}