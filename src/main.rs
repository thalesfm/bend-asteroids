mod app;
mod convert;

use app::App;
use convert::{from_hvm, FromHvm};
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
    let mut app = App::load_from_file("game/main.hvm").unwrap();
    let mut state = app.init().unwrap();

    loop {
        clear_background(Color::new(0.1, 0.2, 0.3, 1.0));
        let value = app.draw(state.clone()).unwrap();
        let value = from_hvm::<f32>(&value);
        draw_text(format!("value: {:?}", value).as_str(), 64.0, 64.0, 30.0, WHITE);
        state = app.tick(state).unwrap();
        next_frame().await
    }
}