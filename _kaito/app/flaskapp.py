from flask import Flask, request, jsonify
import openai

app = Flask(__name__)

# Set your Azure OpenAI API key
openai.api_key = 'YOUR_AZURE_OPENAI_API_KEY'

@app.route('/chat', methods=['POST'])
def chat():
    user_input = request.json.get('message')
    response = openai.ChatCompletion.create(
        model="gpt-4o",  # Updated to use GPT-4o
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": user_input}
        ],
        max_tokens=150
    )
    return jsonify(response.choices[0].message['content'].strip())

if __name__ == '__main__':
    app.run(debug=True)
