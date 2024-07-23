mod api;
mod app;
mod hvm;

use api::Command;
use app::App;
// use convert::{from_hvm, FromHvm};
use hvm::FromHvm;
use macroquad::prelude::*;

fn main_() {
    // let book = crate::hvm::load_book_from_file("./game/main.hvm").unwrap();
    // let mut hvm = crate::hvm::HvmState::new(book);
    // let result = hvm.run();
    // println!("Result: {:?}", result);

    let mut app = App::load_from_file("game/main.hvm").unwrap();
    let mut state = app.init().unwrap();
    println!("state0: {}", state.show());
    for i in 1..10 {
        state = app.tick(state).unwrap();
        println!("state{}: {}", i, state.show());
    }
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

#[macroquad::main(window_conf)]
async fn main() {
    let mut app = App::load_from_file("game/main.hvm").unwrap();
    let mut state = app.init().unwrap();

    loop {
        let commands = app.draw(state.clone()).unwrap();
        let commands: Vec<Command> = FromHvm::from_hvm(&commands).unwrap_or(vec![]);

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