# File: ~/.vim/pack/grok_chat/start/grok_chat/python/grok_chat.py
# Description: Python module for handling Grok API requests
# Author: Grok (xAI)
# License: MIT

import os
from openai import OpenAI

def send_to_grok(prompt):
    try:
        # Initialize OpenAI client with xAI's endpoint
        client = OpenAI(
            api_key=os.getenv('XAI_API_KEY'),
            base_url='https://api.x.ai/v1'
        )

        # Send prompt to Grok API
        response = client.chat.completions.create(
            model='grok-beta',
            messages=[
                {'role': 'system', 'content': 'You are Grok, a helpful AI assistant created by xAI.'},
                {'role': 'user', 'content': prompt}
            ],
            temperature=0.7,
            max_tokens=1000
        )

        # Extract and return the response
        return response.choices[0].message.content.strip()

    except Exception as e:
        return f'Error: {str(e)}'