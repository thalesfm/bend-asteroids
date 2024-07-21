mod app;
mod convert;

use winit::{
    event::*,
    event_loop::{EventLoop, EventLoopWindowTarget},
    keyboard::{KeyCode, PhysicalKey},
    window::{Window, WindowBuilder},
};

struct State<'a> {
    surface: wgpu::Surface<'a>,
    device: wgpu::Device,
    queue: wgpu::Queue,
    config: wgpu::SurfaceConfiguration,
    size: winit::dpi::PhysicalSize<u32>,
    // According to the wgpu docs, the window must be dropped after the surface
    // so shit don't break, so we declare it after the surface in the struct
    window: &'a Window,
}

impl<'a> State<'a> {
    async fn new(window: &'a Window) -> State<'a> {
        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends: wgpu::Backends::PRIMARY, // NOTE: Needs to be different for web!
            ..Default::default()
        });

        let surface = instance.create_surface(window).unwrap();

        let adapter = instance.request_adapter(
            &wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::HighPerformance,
                compatible_surface: Some(&surface),
                force_fallback_adapter: false,
            }
        ).await.unwrap();

        let (device, queue) = adapter.request_device(
            &wgpu::DeviceDescriptor {
                label: None,
                required_features: wgpu::Features::empty(),
                required_limits: wgpu::Limits::default(), // NOTE: Needs to be different for web!
                memory_hints: wgpu::MemoryHints::default(),
            },
            None,
        ).await.unwrap();

        let size = window.inner_size();
        let surface_caps = surface.get_capabilities(&adapter);
        let surface_format = surface_caps.formats.iter()
            .find(|format| format.is_srgb())
            .copied()
            .unwrap_or(surface_caps.formats[0]);
        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format: surface_format,
            width: size.width,
            height: size.height,
            present_mode: wgpu::PresentMode::AutoVsync,
            alpha_mode: surface_caps.alpha_modes[0],
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        };

        Self { window, surface, device, queue, config, size }
    }

    fn window(&self) -> &Window {
        &self.window
    }

    fn resize(&mut self, new_size: winit::dpi::PhysicalSize<u32>) {
        if new_size.width <= 0 || new_size.height <= 0 {
            return;
        }
        self.size = new_size;
        self.config.width = new_size.width;
        self.config.height = new_size.height;
        self.surface.configure(&self.device, &self.config);
    }

    fn input(&mut self, event: &WindowEvent) -> bool {
        false // do not capture
    }

    fn update(&mut self) {
        // TODO
    }

    fn render(&mut self) -> Result<(), wgpu::SurfaceError> {
        let output = self.surface.get_current_texture()?;
        let view = output.texture.create_view(&Default::default());
        let mut encoder = self.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });

        let _render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: Some("Render pass"),
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view: &view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color {
                        r: 0.1,
                        g: 0.2,
                        b: 0.3,
                        a: 1.0,
                    }),
                    store: wgpu::StoreOp::Store,
                },
            })],
            depth_stencil_attachment: None,
            occlusion_query_set: None,
            timestamp_writes: None,
        });
        drop(_render_pass);
        
        self.queue.submit(std::iter::once(encoder.finish()));
        output.present();

        Ok(())
    }
}

async fn run(event_loop: EventLoop<()>, window: Window) {
    
    let mut state = State::new(&window).await;

    let _ = event_loop.run(move |event, control_flow| {
        let event = match event {
            Event::AboutToWait => {
                state.window().request_redraw();
                return; // HACK?
            }
            Event::WindowEvent { ref event, window_id } if window_id == state.window().id() => {
                event
            }
            _ => {
                return
            }
        };
        if state.input(event) {
            return;
        }
        match event {
            WindowEvent::CloseRequested => control_flow.exit(),
            WindowEvent::RedrawRequested => {
                state.update();
                match state.render() {
                    Ok(_) => {}
                    Err(wgpu::SurfaceError::Lost) => state.resize(state.size),
                    Err(wgpu::SurfaceError::OutOfMemory) => control_flow.exit(),
                    Err(e) => eprintln!("{:?}", e),
                };
            },
            WindowEvent::Resized(physical_size) => state.resize(*physical_size),
            _ => {}
        };
    });
}

fn main() {
    let event_loop = EventLoop::new().unwrap();
    let window = WindowBuilder::new().build(&event_loop).unwrap();

    // app::run_file("game/main.hvm");

    env_logger::init();
    pollster::block_on(run(event_loop, window));
}