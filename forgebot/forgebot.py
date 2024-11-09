from flask import Flask, request
from twilio.twiml.messaging_response import MessagingResponse
import openai
import os

# Initialize the Flask App
app = Flask(__name__)

# Set up the OpenAI API key from environment variables
openai.api_key = os.environ.get("OPENAI_API_KEY")

# Define a function to generate answers using ChatGPT
def generate_answer(question):
    model_engine = "gpt-3.5-turbo"  # Update to "gpt-4" if you have access

    response = openai.chat.completions.create(
        model=model_engine,
        messages=[{"role": "user", "content": question}],
        max_tokens=1024,
        temperature=0.7,
    )

    answer = response.choices[0].message.content.lstrip(question).strip()
    return answer

# Define a route to handle incoming requests
@app.route('/chatgpt', methods=['POST'])
def chatgpt():
    incoming_que = request.values.get('Body', '').strip()
    print("Question:", incoming_que)

    # Generate the answer using ChatGPT
    answer = generate_answer(incoming_que)
    print("BOT Answer:", answer)

    # Send the response back to the user
    bot_resp = MessagingResponse()
    msg = bot_resp.message()
    return str(msg)

# Run the Flask app
if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=False, port=5000)
