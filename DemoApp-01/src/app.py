import gradio as gr


def record_audio(audio):
    return f"Áudio recebido: {audio}"

demo = gr.Interface(
    fn=record_audio,
    inputs=gr.Audio(type="filepath"),  # sem 'source'
    outputs="text",
    title="Audio Recorder Hello World App",
    description=("Gradio app to record audio and return a confirmation message."),
)

demo.launch(theme="soft")
