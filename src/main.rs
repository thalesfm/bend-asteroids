mod api;
mod app;
mod hvm;

use macroquad::prelude::*;
use api::Command;
use app::App;
use hvm::FromHvm;

fn main() {
    let book = hvm::load_book_from_file("main.hvm").unwrap();
    let mut hvm = hvm::HvmState::new(book);
    let main = hvm.get_ref("main").unwrap();
    let state = hvm.pop_raw(main).unwrap();
    println!("state: {:?}", state);
}

fn window_conf() -> Conf {
    Conf {
        window_title: "Bend app".to_owned(),
        window_width: 640,
        window_height: 480,
        window_resizable: false,
        ..Default::default()
    }
}

// #[macroquad::main(window_conf)]
async fn main_() {
    let mut app = App::load_from_file("main.hvm").unwrap();
    let mut state = app.init().unwrap();
    // println!("state: {:?}", state);
    println!("state: {:?}", f32::from_hvm(&state));

    loop {
        // let commands = app.draw(state.clone()).unwrap();
        // println!("commands: {:?}", commands);
        let commands = vec![];

        for command in commands {
            match command {
                Command::Clear { color } => clear_background(color),
                Command::DrawLine { x1, y1, x2, y2, color } => draw_line(x1, y1, x2, y2, 5.0, color),
            }
        }

        // draw_text(format!("value: {:?}", value).as_str(), 64.0, 64.0, 30.0, WHITE);
        state = app.tick(state).unwrap();
        println!("state: {:?}", f32::from_hvm(&state));
        next_frame().await
    }
}
