mod app;
mod convert;

use macroquad::prelude::*;

fn window_conf() -> Conf {
    Conf {
        window_title: "Bend app".to_owned(),
        window_width: 640,
        window_height: 480,
        window_resizable: false,
        ..Default::default()
    }
}

#[macroquad::main(window_conf)]
async fn main() {
    // app::run_file("game/main.hvm");

    loop {
        clear_background(Color::new(0.1, 0.2, 0.3, 1.0));
        next_frame().await
    }
}