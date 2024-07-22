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
        clear_background(Color::new(0.1, 0.2, 0.3, 1.0));
        let value = app.draw(state.clone()).unwrap();

        /*
        // println!("{:?}\n", value);
        println!("{}", value.show());
        match &value.root {
            hvm::ast::Tree::Con { fst, snd } => {
                if let hvm::ast::Tree::Var { .. } = **snd {
                    let args = convert::call_args(&fst);
                    println!("args: {:?}", args);
                }
            }
            _ => {}
        }
        */

        // let value = from_hvm::<f32>(&value);
        // let value = from_hvm::<Vec<u32>>(&value);
        let value = from_hvm::<Command>(&value);
        draw_text(format!("value: {:?}", value).as_str(), 64.0, 64.0, 30.0, WHITE);
        state = app.tick(state).unwrap();
        next_frame().await
    }
}