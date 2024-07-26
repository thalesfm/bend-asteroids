mod api;
mod app;
mod from_term;

use std::marker::PhantomData;

use macroquad::prelude::*;
use macroquad::input::utils::{register_input_subscriber, repeat_all_miniquad_input};
use macroquad::miniquad::{EventHandler, KeyMods};

use api::Command;
use app::{App, State};

struct KeyEventForwarder<'a> {
    app: &'a App,
    state: &'a mut State,
}

impl<'a> KeyEventForwarder<'a> {
    fn new(app: &'a App, state: &'a mut State) -> Self {
        KeyEventForwarder { app: app, state: state }
    }
}

impl<'a> EventHandler for KeyEventForwarder<'a> {
    fn update(&mut self) {
        // Do nothing
    }

    fn draw(&mut self) {
        // Do nothing
    }

    fn key_down_event(&mut self, keycode: KeyCode, _keymods: KeyMods, _repeat: bool) {
        *self.state = self.app.when(keycode, self.state).unwrap();
    }
}

fn window_conf() -> Conf {
    Conf {
        window_title: "Bend Game".to_owned(),
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
    let subscriber = register_input_subscriber();

    loop {
        // Draw commands returned by the app
        let commands = app.draw(&state).unwrap_or(vec![]);
        for command in commands {
            match command {
                Command::Clear { color } => {
                    clear_background(color);
                }
                Command::DrawLine { x1, y1, x2, y2, thickness, color } => {
                    draw_line(x1, y1, x2, y2, thickness, color);
                }
                Command::DrawText { text, x, y, font_size, color } => {
                    draw_text(text.as_str(), x, y, font_size, color);
                }
            }
        }

        // Forward all key events since last frame to app
        let mut forwarder = KeyEventForwarder::new(&app, &mut state);
        repeat_all_miniquad_input(&mut forwarder, subscriber);
        // drop(forwarder); // Implicit?

        // Update the app's state
        state = app.tick(&state).unwrap();

        let elapsed = 1000.0 * get_frame_time();
        draw_text(format!("{:2.2} ms", elapsed).as_str(), 20.0, 32.0, 24.0, WHITE);
        next_frame().await
    }
}