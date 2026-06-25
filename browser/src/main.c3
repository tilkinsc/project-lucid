
import std::io;
import std::math;
import std::math::vector;
import std::math::matrix;
import raylib6::rl;
import render;
import pipeline;

fn void main()
{
	rl::init_window(800, 600, "Hello, World!");
	defer rl::close_window();

	rl::set_target_fps(60);

	RLFont interRegular = rl::load_font_ex("assets/font/inter/Inter_28pt-Regular.ttf", 64, null, 0);
	RLFont interBold = rl::load_font_ex("assets/font/inter/Inter_28pt-Bold.ttf", 64, null, 0);
	RLFont interItalic = rl::load_font_ex("assets/font/inter/Inter_28pt-Italic.ttf", 64, null, 0);
	RLFont interBoldItalic = rl::load_font_ex("assets/font/inter/Inter_28pt-BoldItalic.ttf", 64, null, 0);
	interRegular.texture.set_filter(BILINEAR);
	interBold.texture.set_filter(BILINEAR);
	interItalic.texture.set_filter(BILINEAR);
	interBoldItalic.texture.set_filter(BILINEAR);

	Scene scene;
	scene.allocator = mem;
	scene.viewport = { 800, 600 };
	scene.fonts = { interRegular, interBold, interItalic, interBoldItalic };
	scene.dirtyFlags = DirtyFlags.MEASURE | DirtyFlags.LAYOUT | DirtyFlags.CLIP;
	defer scene.emoji_cache.free();

	// build your element tree into scene.root...

	// root panel — full viewport, dark background
	scene.root.kind             = ElementKind.PANEL;
	scene.root.render.visible   = true;
	scene.root.render.color     = { 49, 51, 56, 255 };
	scene.root.layout.sizeScale = { 1, 1 };

	// a white panel top left, fixed size, clips its children
	Element* box  = mem::new(Element);
	box.make_panel(20, 20, 400, 300, (RLColor){ 1, 1, 1, 255 }, true);
	scene.root.add_child(box);

	// normal text inside the box
	Element* t1   = mem::new(Element);
	t1.make_text("Hello *world*!", 24, (RLColor){ 49, 51, 56, 255 });
	t1.layout.positionOffset = { 8, 8 };
	box.add_child(t1);

	// bold-italic line below it
	Element* t2 = mem::new(Element);
	t2.make_text("_*bold-italic text here*_", 24, (RLColor){ 49, 51, 56, 255 });
	t2.layout.positionOffset = { 8, 40 };
	box.add_child(t2);

	// emoji line
	Element* t3 = mem::new(Element);
	t3.make_text("Smile emoji: 🎅🏿 ❤️‍🔥 👩🏿‍❤️‍💋‍👨🏾", 24, (RLColor){ 49, 51, 56, 255 });
	t3.layout.positionOffset = { 8, 72 };
	box.add_child(t3);

	// a second panel bottom right to test positioning
	Element* box2 = mem::new(Element);
	box2.make_panel(440, 20, 340, 100, (RLColor){ 80, 120, 200, 255 }, false);
	scene.root.add_child(box2);

	Element* t4   = mem::new(Element);
	t4.make_text("*Blue panel*", 28, rl::WHITE);
	t4.layout.positionOffset = { 8, 8 };
	box2.add_child(t4);

	// a clipping test — panel that cuts off text deliberately
	Element* clipBox = mem::new(Element);
	clipBox.make_panel(20, 340, 200, 40, (RLColor){ 200, 80, 80, 255 }, true);
	scene.root.add_child(clipBox);

	Element* t5   = mem::new(Element);
	t5.make_text("This text is too long to fit", 24, rl::WHITE);
	t5.layout.positionOffset = { 4, 8 };
	clipBox.add_child(t5);

	while (!rl::window_should_close())
	{
		scene.run_passes();
		rl::begin_drawing();
		defer rl::end_drawing();
		rl::clear_background({49, 51, 56, 255});
		scene.render_pass(&scene.root);
	}


	// RichText test = render::create_rich_text("Hello *world*! This is _italic_ and **bold** _*bold-italic*_. Smile emoji: 🎅🏿");
	// defer test.free();

	// while (!rl::window_should_close()) {
	// 	rl::begin_drawing();
	// 	defer rl::end_drawing();

	// 	rl::clear_background({49, 51, 56, 255});
	
	// 	float cursor = 0.0f;
	// 	foreach (sz i, TextRun run : test.runs) {
	// 		switch (run.kind) {
	// 			case RunKind.RUN_TEXT:
	// 				switch (run.style) {
	// 					case FontStyle.NORMAL:
	// 						rl::draw_text_ex(interRegular, (ZString)run.text, {10 + cursor, 10}, 32, 0, rl::WHITE);
	// 						cursor += rl::measure_text_ex(interRegular, (ZString)run.text, 32, 0).x;
	// 						break;
	// 					case FontStyle.BOLD:
	// 						rl::draw_text_ex(interBold, (ZString)run.text, {10 + cursor, 10}, 32, 0, rl::WHITE);
	// 						cursor += rl::measure_text_ex(interBold, (ZString)run.text, 32, 0).x;
	// 						break;
	// 					case FontStyle.ITALIC:
	// 						rl::draw_text_ex(interItalic, (ZString)run.text, {10 + cursor, 10}, 32, 0, rl::WHITE);
	// 						cursor += rl::measure_text_ex(interItalic, (ZString)run.text, 32, 0).x;
	// 						break;
	// 					case FontStyle.BOLD_ITALIC:
	// 						rl::draw_text_ex(interBoldItalic, (ZString)run.text, {10 + cursor, 10}, 32, 0, rl::WHITE);
	// 						cursor += rl::measure_text_ex(interBoldItalic, (ZString)run.text, 32, 0).x;
	// 						break;
	// 				}
	// 			break;
	// 			case RunKind.RUN_EMOJI:
	// 				float size = 32.0f;
	// 				if (try RLTexture2D tex = emoji_cache.get_texture(run.text)) {
	// 					rl::draw_texture_ex(tex, {10 + cursor, 10}, 0.0f, size / (float)tex.width, rl::WHITE);
	// 				} else {
	// 					io::printfn("Failed to load emoji: %s", run.text);
	// 					rl::draw_text_ex(interRegular, "?", {10 + cursor, 10}, 32, 0, rl::WHITE);
	// 				}
	// 				cursor += size;
	// 				break;
	// 		}
	// 	}
	// }
}
