mod api;
mod app;
mod convert;

use api::Command;
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
        let commands = app.draw(state.clone()).unwrap();
        let commands = from_hvm::<Vec<Command>>(&commands).unwrap_or(vec![]);

        for command in commands {
            match command {
                Command::Clear { color } => clear_background(color),
                Command::DrawLine { x1, y1, x2, y2, color } => draw_line(x1, y1, x2, y2, 5.0, color),
            }
        }

        // draw_text(format!("value: {:?}", value).as_str(), 64.0, 64.0, 30.0, WHITE);
        state = app.tick(state).unwrap();
        next_frame().await
    }
}