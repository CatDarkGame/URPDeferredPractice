using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomDeferred.RendererFeature
{
    public class CustomGBufferRendererFeature : ScriptableRendererFeature
    {
        [Header("Pass Settings")]
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;

        private CustomGBufferRenderPass _customGBufferRenderPass = null;

        public override void Create()
        {
            _customGBufferRenderPass = new CustomGBufferRenderPass(passEvent);
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            _customGBufferRenderPass?.Dispose();
            _customGBufferRenderPass = null;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(_customGBufferRenderPass);
        }
    }

}

