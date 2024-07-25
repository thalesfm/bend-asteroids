mod api;
mod app;
mod from_term;

use macroquad::prelude::*;
use api::Command;
use app::App;

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
    let app = App::load_from_file("bend-game/main.bend").unwrap();
    let mut state = app.init().unwrap();

    loop {
        let commands = app.draw(&state).unwrap_or(vec![]);
        for command in commands {
            match command {
                Command::Clear { color } => clear_background(color),
                Command::DrawLine { x1, y1, x2, y2, color } => draw_line(x1, y1, x2, y2, 1.0, color),
            }
        }

        state = app.tick(&state).unwrap();
        let elapsed = 1000.0 * get_frame_time();
        draw_text(format!("{:2.2} ms", elapsed).as_str(), 20.0, 32.0, 24.0, WHITE);
        next_frame().await
    }
}