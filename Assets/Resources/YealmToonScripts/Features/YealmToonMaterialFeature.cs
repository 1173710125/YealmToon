using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;

public class YealmToonMaterialFeature : ScriptableRendererFeature
{
    //un-comment below line to use rendering layer mask to filter out objects
    //[RenderingLayerMask]
    private int m_renderingLayerMask;

    public RenderQueueRange Range = RenderQueueRange.opaque;
    private RenderPassEvent Event = RenderPassEvent.BeforeRenderingOpaques;
    private string MaterialPassShaderTag = "YealmToonMaterialPass";
    YealmToonMaterialPass m_YealmToonMaterialPass;

    class YealmToonMaterialPass : ScriptableRenderPass
    {
        private RTHandle m_materialPassTarget;
        private RTHandle m_detphTarget;

        private FilteringSettings m_filteringSettings;
        private RenderStateBlock m_renderStateBlock;
        private ShaderTagId m_shaderTagId;
        private string m_profilerTag;

        public YealmToonMaterialPass(string profilerTag, string shaderTagId, RenderPassEvent evt,
                RenderQueueRange renderQueueRange, uint renderingLayerMask, StencilState stencilState,
                int stencilReference)
        {
            m_profilerTag = profilerTag;
            renderPassEvent = evt;
            m_filteringSettings = new FilteringSettings(renderQueueRange);
            //un-comment below line to use rendering layer mask to filter out objects
            //m_filteringSettings.renderingLayerMask = renderingLayerMask;
            m_renderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);
            m_shaderTagId = new ShaderTagId(shaderTagId);
        }

        // This class stores the data needed by the RenderGraph pass.
        // It is passed as a parameter to the delegate function that executes the RenderGraph pass.
        private class PassData
        {
            public TextureHandle Destination;
            public TextureHandle DesinationDepth;
            public RendererListHandle RendererListHandle;
        }

        static readonly int s_toonMaterialTexture = Shader.PropertyToID("_YealmToonMaterialTexture");
        static readonly int s_toonDepthTexture = Shader.PropertyToID("_YealmToonDepthTexture");

        // This static method is passed as the RenderFunc delegate to the RenderGraph render pass.
        // It is used to execute draw commands.
        static void ExecutePass(PassData data, RasterGraphContext context)
        {
        }

        // RecordRenderGraph is where the RenderGraph handle can be accessed, through which render passes can be added to the graph.
        // FrameData is a context container through which URP resources can be accessed and managed.
        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            const string passName = "YealmToonMaterialPass";

            // This adds a raster render pass to the graph, specifying the name and the data type that will be passed to the ExecutePass function.
            using (var builder = renderGraph.AddRasterRenderPass<PassData>(passName, out var passData))
            {
                    // Access the relevant frame data from the Universal Render Pipeline
                    UniversalRenderingData universalRenderingData = frameData.Get<UniversalRenderingData>();
                    UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
                    UniversalLightData lightData = frameData.Get<UniversalLightData>();

                    var sortFlags = SortingCriteria.CommonOpaque;
                    DrawingSettings drawSettings =
 RenderingUtils.CreateDrawingSettings(m_shaderTagId, universalRenderingData, cameraData, lightData, sortFlags);

                    var param =
 new RendererListParams(universalRenderingData.cullResults, drawSettings, m_filteringSettings);
                    passData.RendererListHandle = renderGraph.CreateRendererList(param);
                    
                    RenderTextureDescriptor desc = new RenderTextureDescriptor(
                        cameraData.cameraTargetDescriptor.width,
                        cameraData.cameraTargetDescriptor.height);
                    desc.colorFormat = RenderTextureFormat.ARGB32;
                    desc.depthBufferBits = 0;
                    TextureHandle destination =
 UniversalRenderer.CreateRenderGraphTexture(renderGraph, desc, "_YealmToonMaterialTexture", false);
                    passData.Destination = destination;
                    
                    desc.colorFormat = RenderTextureFormat.Depth;
                    desc.depthBufferBits = cameraData.cameraTargetDescriptor.depthBufferBits;
                    TextureHandle destinationDepth =
 UniversalRenderer.CreateRenderGraphTexture(renderGraph, desc, "_YealmToonDepthTexture", false);
                    passData.DesinationDepth = destinationDepth;
                    
                    builder.UseRendererList(passData.RendererListHandle);
                    builder.SetRenderAttachment(passData.Destination, 0);
                    builder.SetRenderAttachmentDepth(passData.DesinationDepth, AccessFlags.Write);
                    builder.AllowPassCulling(false);
                    builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
                    {
                        context.cmd.ClearRenderTarget(RTClearFlags.All, Color.clear, 1, 0);
                        context.cmd.DrawRendererList(data.RendererListHandle); 
                    });
                    builder.SetGlobalTextureAfterPass(passData.Destination, s_toonMaterialTexture);
                    builder.SetGlobalTextureAfterPass(passData.DesinationDepth, s_toonDepthTexture);
            }
        }

        // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        [Obsolete("Compatible Mode only", false)]
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        [Obsolete("Compatible Mode only", false)]
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
        }

        // NOTE: This method is part of the compatibility rendering path, please use the Render Graph API above instead.
        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }

        public void Dispose()
        {
            m_materialPassTarget?.Release();
            m_detphTarget?.Release();
        }
    }

    /// <inheritdoc/>
    public override void Create()
    {
        m_YealmToonMaterialPass = new YealmToonMaterialPass(name, MaterialPassShaderTag, Event, Range,
            (uint)m_renderingLayerMask, StencilState.defaultValue, 0);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_YealmToonMaterialPass);
    }
}
