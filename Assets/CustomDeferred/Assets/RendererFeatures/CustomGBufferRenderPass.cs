using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomDeferred.RendererFeature
{
    public class CustomGBufferRenderPass : ScriptableRenderPass
    {
        private const string k_ProfilingSamplerName = "CustomGBufferPass";

        List<ShaderTagId> _shaderTagIdList = new List<ShaderTagId>();
        private RenderQueueType _renderQueueType = RenderQueueType.Opaque;
        private RenderQueueRange _renderQueueRange = RenderQueueRange.opaque;
        private FilteringSettings _filteringSettings;

        public CustomGBufferRenderPass(RenderPassEvent passEvent)
        {
            base.profilingSampler = new ProfilingSampler(k_ProfilingSamplerName);
            this.renderPassEvent = passEvent;
            _filteringSettings = new FilteringSettings(_renderQueueRange);

            _shaderTagIdList.Clear();
            _shaderTagIdList.Add(new ShaderTagId("CustomGBuffer"));
        }

        public void Dispose()
        {
            _shaderTagIdList.Clear();
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, profilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                SortingCriteria sortingCriteria = (_renderQueueType == RenderQueueType.Transparent)
                  ? SortingCriteria.CommonTransparent
                  : renderingData.cameraData.defaultOpaqueSortFlags;

                DrawingSettings drawingSettings = CreateDrawingSettings(_shaderTagIdList, ref renderingData, sortingCriteria);
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filteringSettings);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

        }
    }
}