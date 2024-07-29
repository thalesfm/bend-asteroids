mod api;
mod app;
mod convert;
mod hvm;

use macroquad::prelude::*;
use macroquad::input::utils::{register_input_subscriber, repeat_all_miniquad_input};
use macroquad::miniquad::{EventHandler, KeyMods};

use api::{Command, Event};
use app::{App, State};

struct KeyEventForwarder<'a, 'b> {
    app: &'a mut App<'b>,
    state: &'a mut State,
}

impl<'a, 'b> KeyEventForwarder<'a, 'b> {
    fn new(app: &'a mut App<'b>, state: &'a mut State) -> Self {
        KeyEventForwarder { app: app, state: state }
    }
}

impl<'a, 'b> EventHandler for KeyEventForwarder<'a, 'b> {
    fn update(&mut self) {
        // Do nothing
    }

    fn draw(&mut self) {
        // Do nothing
    }

    fn key_down_event(&mut self, keycode: KeyCode, _keymods: KeyMods, repeat: bool) {
        if !repeat {
            let event = Event::KeyDown(keycode);
            *self.state = self.app.when(event, self.state).unwrap();
        }
    }

    fn key_up_event(&mut self, keycode: KeyCode, _keymods: KeyMods) {
        let event = Event::KeyUp(keycode);
        *self.state = self.app.when(event, self.state).unwrap();
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
    let mut app = App::load_from_file("bend-game/main.bend").unwrap();
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
                // Command::Exit => {
                //     return;
                // }
            }
        }

        if is_key_pressed(KeyCode::Escape) {
            return;
        }

        // Forward all key events since last frame to app
        let mut forwarder = KeyEventForwarder::new(&mut app, &mut state);
        repeat_all_miniquad_input(&mut forwarder, subscriber);
        // drop(forwarder); // Implicit?

        // Update the app's state
        println!("state: {}", state);
        state = app.tick(&state).unwrap();

        let elapsed = 1000.0 * get_frame_time();
        draw_text(format!("{:2.2} ms", elapsed).as_str(), 20.0, 32.0, 24.0, WHITE);
        next_frame().await
    }
}