module pipeline;

import std::math;
import std::math::vector;
import render;
import raylib6::rl;
import std::io;

const ARENA_SIZE = 64 * 4096; // 64 pages

struct Scene
{
    DynamicArenaAllocator arena;
	Allocator allocator;
    Element root;
    Vec2 viewport;
    FontSet fonts;
    DirtyFlags dirtyFlags;
    EmojiCache emoji_cache;
}

fn void Scene.init(&self)
{
	self.arena.init(mem, ARENA_SIZE);
	self.root.init(&self.arena);
}

fn void Scene.free_elements(&self)
{
	self.arena.reset();
	self.arena.free();
}

fn void Scene.free_emoji_cache(&self)
{
	self.emoji_cache.free();
}

fn void Scene.free(&self)
{
	self.fonts.free();
	self.free_emoji_cache();
}

fn void Scene.run_passes(&self)
{
    if (self.dirtyFlags & DirtyFlags.MEASURE)
    {
        self.measure_pass(&self.root);
    }
    if (self.dirtyFlags & DirtyFlags.LAYOUT)
    {
        self.layout_pass(&self.root, { 0, 0, self.viewport.x, self.viewport.y });
    }
    if (self.dirtyFlags & DirtyFlags.CLIP)
    {
        self.clip_pass(&self.root, { 0, 0, self.viewport.x, self.viewport.y });
    }
    self.dirtyFlags = DirtyFlags.NONE;
}

fn void Scene.layout_pass(&self, Element* element, Rect parentBounds)
{
    Vec2 parentSize = { parentBounds.width, parentBounds.height };

    Vec2 size = {
        parentSize.x * element.layout.sizeScale.x + element.layout.sizeOffset.x,
        parentSize.y * element.layout.sizeScale.y + element.layout.sizeOffset.y,
    };

    // for TEXT and IMAGE, if sizeScale is zero, fall back to measured size
    if (size.x == 0 && size.y == 0) size = element.measured.size;

    Vec2 position = {
        parentBounds.x + parentSize.x * element.layout.positionScale.x + element.layout.positionOffset.x,
        parentBounds.y + parentSize.y * element.layout.positionScale.y + element.layout.positionOffset.y,
    };

    // anchor point shifts the element relative to its own size
    position.x -= size.x * element.layout.anchorPoint.x;
    position.y -= size.y * element.layout.anchorPoint.y;

    element.layoutState.worldBounds = { position.x, position.y, size.x, size.y };

    element.dirtyFlags &= ~DirtyFlags.LAYOUT;

    foreach (Element* child : element.children)
    {
        self.layout_pass(child, element.layoutState.worldBounds);
    }
}

fn void Scene.clip_pass(&self, Element* element, Rect parentClip)
{
    Rect worldBounds = element.layoutState.worldBounds;

    element.layoutState.clip = {
        .x      = math::max(worldBounds.x, parentClip.x),
        .y      = math::max(worldBounds.y, parentClip.y),
        .width  = math::min(worldBounds.x + worldBounds.width,  parentClip.x + parentClip.width)  - math::max(worldBounds.x, parentClip.x),
        .height = math::min(worldBounds.y + worldBounds.height, parentClip.y + parentClip.height) - math::max(worldBounds.y, parentClip.y),
    };

    // clamp negatives — element is fully clipped
    if (element.layoutState.clip.width  < 0) element.layoutState.clip.width  = 0;
    if (element.layoutState.clip.height < 0) element.layoutState.clip.height = 0;

    Rect childClip = element.layout.clipChildren
        ? element.layoutState.clip
        : parentClip;

    element.dirtyFlags &= ~DirtyFlags.CLIP;

    foreach (Element* child : element.children)
    {
        self.clip_pass(child, childClip);
    }
}

fn void Scene.render_pass(&self, Element* element)
{
    if (!element.render.visible) return;
    if (element.layoutState.clip.width  <= 0) return;
    if (element.layoutState.clip.height <= 0) return;

    Rect clip = element.layoutState.clip;
    rl::begin_scissor_mode(
        (int)clip.x, (int)clip.y,
        (int)clip.width, (int)clip.height
    );

    switch (element.kind)
    {
        case ElementKind.PANEL:
            Rect wb = element.layoutState.worldBounds;
            rl::draw_rectangle_rec(wb, element.render.color);
        case ElementKind.TEXT:
            TextData* td = (TextData*)element.data;
            float cursor = element.layoutState.worldBounds.x;
            float y      = element.layoutState.worldBounds.y;
            foreach (TextRun run : td.richText.runs)
            {
                switch (run.kind)
                {
                    case RunKind.RUN_TEXT:
                        RLFont font = self.fonts.for_style(run.style);
                        rl::draw_text_ex(font, (ZString)run.text, { cursor, y }, td.fontSize, 0, element.render.color);
                        cursor += rl::measure_text_ex(font, (ZString)run.text, td.fontSize, 0).x;
                    case RunKind.RUN_EMOJI:
                        if (try RLTexture2D tex = self.emoji_cache.get_texture(run.text))
                        {
                            float scale = td.fontSize / (float)tex.width;
                            rl::draw_texture_ex(tex, { cursor, y }, 0.0f, scale, rl::WHITE);
                        }
                        cursor += td.fontSize;
                }
            }

        case ElementKind.IMAGE:
            // TODO when image loading is added
			break;
    }

    rl::end_scissor_mode();

    foreach (Element* child : element.children)
    {
        self.render_pass(child);
    }
}
