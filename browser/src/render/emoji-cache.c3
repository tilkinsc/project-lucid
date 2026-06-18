module render;

import raylib6::rl;
import std::collections::map;

struct EmojiCache
{
	HashMap{String, RLTexture2D} textures;
}

fn void EmojiCache.init(&self, Allocator allocator)
{
    self.textures.init(allocator);
}

fn void EmojiCache.free(&self)
{
    self.textures.@each(;key, value) {
        rl::unload_texture(value);
    };
    self.textures.clear();
}

fn RLTexture2D? EmojiCache.get_texture(&self, String emoji)
{
	RLTexture2D? output = self.textures.get(emoji);
	if (catch output) {
		RLTexture2D tex = rl::load_texture((ZString)"assets/emoji/".concat(tmem, emoji));
		if (tex.id != 0) {
			self.textures.set(emoji, tex);
			output = tex;
		}
	}
	return output;
}
