using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(CustomPostProcessingRenderer), PostProcessEvent.AfterStack, "Custom/CustomPostProcessing")]
public sealed class CustomPostProcessing : PostProcessEffectSettings
{
    [Range(0f, 1f)]
    public FloatParameter edgeThreshold = new FloatParameter { value = 0.5f };
    public FloatParameter edgeSize = new FloatParameter { value = 1f };
    public ColorParameter edgeColor = new ColorParameter { value = new Color(1,1,1,1) };
}

public sealed class CustomPostProcessingRenderer : PostProcessEffectRenderer<CustomPostProcessing>
{
    private Material _mat;
    public override void Init()
    {
        base.Init();
        _mat = new Material(Shader.Find("CustomPP/CustomPostProcessing"));
    }

    public override void Render(PostProcessRenderContext context)
    {
        _mat.SetFloat("_EdgeThreshold", settings.edgeThreshold);
        _mat.SetFloat("_EdgeSize", settings.edgeSize);
        _mat.SetColor("_EdgeColor", settings.edgeColor);
        context.command.Blit(context.source, context.destination,_mat);
    }
}
