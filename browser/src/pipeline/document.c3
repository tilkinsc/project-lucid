module pipeline;

import std::math::rectangle;
import std::math;
import std::math::vector;
import std::collections::list;
import raylib6::rl;

const CHILDREN_INITIAL_CAPACITY = 8;

enum ElementKind
{
	PANEL,
	TEXT,
	IMAGE,
}

struct Layout
{
    Vec2 positionScale;
    Vec2 positionOffset;
    Vec2 sizeScale;
    Vec2 sizeOffset;
    Vec2 anchorPoint;
    bool clipChildren;
}

struct Measured
{
    Vec2 size;
}

struct LayoutState
{
    Rect worldBounds;
    Rect clip;
}

struct RuntimeState
{
	Vec2 offset;
	float rotation;
	float scale;
	bool overrideLayout;
}

struct Render
{
    RLColor color;
    float opacity;
    bool visible;
}

constdef DirtyFlags
{
	NONE = 0,
	MEASURE = 1,
	LAYOUT = 2,
	CLIP = 4,
	RENDER = 8,
}

struct Element
{
    List{Element*} children;
    Element* parent;
    Layout layout;
    Render render;
    ElementKind kind;
    void* data;
    Measured measured;
    LayoutState layoutState;
	RuntimeState runtimeState;
    DirtyFlags dirtyFlags;
}

fn void Element.init(&self, Allocator allocator)
{
    self.children.init(allocator, CHILDREN_INITIAL_CAPACITY);
}

fn void Element.free(&self)
{
	foreach (Element* child : self.children)
	{
		child.free();
	}
}

fn Element* Element.make_text(&self, String text, float fontSize, RLColor color)
{
    TextData* td = mem::new(TextData);
    td.raw       = text;
    td.fontSize  = fontSize;
    td.dirty     = true;

    self.kind              = ElementKind.TEXT;
    self.data              = td;
    self.render.color      = color;
    self.render.visible    = true;
    self.render.opacity    = 1.0f;
    self.layout.sizeScale  = { 0, 0 };
    self.layout.sizeOffset = { 0, 0 };
    return self;
}

fn Element* Element.make_panel(&self, float x, float y, float width, float height, RLColor color, bool clip)
{
    self.kind                  = ElementKind.PANEL;
    self.render.color          = color;
    self.render.visible        = true;
    self.render.opacity        = 1.0f;
    self.layout.positionOffset = { x, y };
    self.layout.sizeOffset     = { width, height };
    self.layout.clipChildren   = clip;
    return self;
}

<* @require child != null *>
fn void Element.add_child(&self, Element* child)
{
    child.parent = self;
    self.children.push(child);
}
