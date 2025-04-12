from openai import AzureOpenAI
import streamlit as st

import os
from dotenv import load_dotenv

st.title("ChatGPT Streamlit Demo")

load_dotenv(override=False)

with st.sidebar.expander("Environment Variables"):
    st.write("AZURE_OPENAI_ENDPOINT", os.getenv("AZURE_OPENAI_ENDPOINT"))
    st.write("AZURE_OPENAI_API_KEY", os.getenv("AZURE_OPENAI_API_KEY"))
    st.write("AZURE_OPENAI_CHATGPT_DEPLOYMENT", os.getenv("AZURE_OPENAI_CHATGPT_DEPLOYMENT"))
    st.write("AZURE_OPENAI_API_VERSION", os.getenv("AZURE_OPENAI_API_VERSION"))

default_prompt = """
You are an AI assistant that helps users.
"""

system_prompt = st.sidebar.text_area("System Prompt", default_prompt, height=200)
seed_message = {"role": "system", "content": system_prompt}

client = AzureOpenAI(
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
)

if "openai_model" not in st.session_state:
    st.session_state["openai_model"] = os.getenv("AZURE_OPENAI_CHATGPT_DEPLOYMENT")

if "messages" not in st.session_state:
    st.session_state.messages = []

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

if prompt := st.chat_input("What is up?"):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        stream = client.chat.completions.create(
            model=st.session_state["openai_model"],
            messages=[
                {"role": m["role"], "content": m["content"]}
                for m in st.session_state.messages
            ],
            stream=True,
        )
        response = st.write_stream(stream)
    st.session_state.messages.append({"role": "assistant", "content": response})

# import streamlit as st
# from streamlit_chat import message
# import dotenv
# import os
# import openai
# import datetime
# import json


# # region ENV + SDK SETUP

# # Load environment variables
# ENV = dotenv.dotenv_values(".env")
# with st.sidebar.expander("Environment Variables"):
#     st.write(ENV)

# # Set up the Open AI Client

# openai.api_type = "azure"
# openai.api_base = "https://ai-service-aks173.cognitiveservices.azure.com" # ENV["AZURE_OPENAI_ENDPOINT"]
# openai.api_version = ENV["AZURE_OPENAI_API_VERSION"]
# openai.api_key = "4239fa0bba324b8b96b28564414c4136" # ENV["AZURE_OPENAI_KEY"]
# # endregion

# # region PROMPT SETUP

# default_prompt = """
# You are an AI assistant  that helps users write concise\
#  reports on sources provided according to a user query.\
#  You will provide reasoning for your summaries and deductions by\
#  describing your thought process. You will highlight any conflicting\
#  information between or within sources. Greet the user by asking\
#  what they'd like to investigate.
# """

# system_prompt = st.sidebar.text_area("System Prompt", default_prompt, height=200)
# seed_message = {"role": "system", "content": system_prompt}
# # endregion

# # region SESSION MANAGEMENT
# # Initialise session state variables
# if "generated" not in st.session_state:
#     st.session_state["generated"] = []
# if "past" not in st.session_state:
#     st.session_state["past"] = []
# if "messages" not in st.session_state:
#     st.session_state["messages"] = [seed_message]
# if "model_name" not in st.session_state:
#     st.session_state["model_name"] = []
# if "cost" not in st.session_state:
#     st.session_state["cost"] = []
# if "total_tokens" not in st.session_state:
#     st.session_state["total_tokens"] = []
# if "total_cost" not in st.session_state:
#     st.session_state["total_cost"] = 0.0
# # endregion

# # region SIDEBAR SETUP

# counter_placeholder = st.sidebar.empty()
# counter_placeholder.write(
#     f"Total cost of this conversation: ${st.session_state['total_cost']:.5f}"
# )
# clear_button = st.sidebar.button("Clear Conversation", key="clear")

# if clear_button:
#     st.session_state["generated"] = []
#     st.session_state["past"] = []
#     st.session_state["messages"] = [seed_message]
#     st.session_state["number_tokens"] = []
#     st.session_state["model_name"] = []
#     st.session_state["cost"] = []
#     st.session_state["total_cost"] = 0.0
#     st.session_state["total_tokens"] = []
#     counter_placeholder.write(
#         f"Total cost of this conversation: £{st.session_state['total_cost']:.5f}"
#     )


# download_conversation_button = st.sidebar.download_button(
#     "Download Conversation",
#     data=json.dumps(st.session_state["messages"]),
#     file_name=f"conversation.json",
#     mime="text/json",
# )

# # endregion


# def generate_response(prompt):
#     st.session_state["messages"].append({"role": "user", "content": prompt})
#     try:
#         completion = openai.ChatCompletion.create(
#             engine=ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"],
#             messages=st.session_state["messages"],
#         )
#         response = completion.choices[0].message.content
#     except openai.error.APIError as e:
#         st.write(response)
#         response = f"The API could not handle this content: {str(e)}"
#     st.session_state["messages"].append({"role": "assistant", "content": response})

#     # print(st.session_state['messages'])
#     total_tokens = completion.usage.total_tokens
#     prompt_tokens = completion.usage.prompt_tokens
#     completion_tokens = completion.usage.completion_tokens
#     return response, total_tokens, prompt_tokens, completion_tokens


# st.title("Streamlit ChatGPT Demo")

# # container for chat history
# response_container = st.container()
# # container for text box
# container = st.container()

# with container:
#     with st.form(key="my_form", clear_on_submit=True):
#         user_input = st.text_area("You:", key="input", height=100)
#         submit_button = st.form_submit_button(label="Send")

#     if submit_button and user_input:
#         output, total_tokens, prompt_tokens, completion_tokens = generate_response(
#             user_input
#         )
#         st.session_state["past"].append(user_input)
#         st.session_state["generated"].append(output)
#         st.session_state["model_name"].append(ENV["AZURE_OPENAI_CHATGPT_DEPLOYMENT"])
#         st.session_state["total_tokens"].append(total_tokens)

#         # from https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/#pricing
#         cost = total_tokens * 0.001625 / 1000

#         st.session_state["cost"].append(cost)
#         st.session_state["total_cost"] += cost


# if st.session_state["generated"]:
#     with response_container:
#         for i in range(len(st.session_state["generated"])):
#             message(
#                 st.session_state["past"][i],
#                 is_user=True,
#                 key=str(i) + "_user",
#                 avatar_style="shapes",
#             )
#             message(
#                 st.session_state["generated"][i], key=str(i), avatar_style="identicon"
#             )
#         counter_placeholder.write(
#             f"Total cost of this conversation: ${st.session_state['total_cost']:.5f}"
#         )

# # import altair as alt
# # import numpy as np
# # import pandas as pd
# # import streamlit as st

# # """
# # # Welcome to Streamlit!

# # Edit `/streamlit_app.py` to customize this app to your heart's desire :heart:.
# # If you have any questions, check out our [documentation](https://docs.streamlit.io) and [community
# # forums](https://discuss.streamlit.io).

# # In the meantime, below is an example of what you can do with just a few lines of code:
# # """

# # num_points = st.slider("Number of points in spiral", 1, 10000, 1100)
# # num_turns = st.slider("Number of turns in spiral", 1, 300, 31)

# # indices = np.linspace(0, 1, num_points)
# # theta = 2 * np.pi * num_turns * indices
# # radius = indices

# # x = radius * np.cos(theta)
# # y = radius * np.sin(theta)

# # df = pd.DataFrame({
# #     "x": x,
# #     "y": y,
# #     "idx": indices,
# #     "rand": np.random.randn(num_points),
# # })

# # st.altair_chart(alt.Chart(df, height=700, width=700)
# #     .mark_point(filled=True)
# #     .encode(
# #         x=alt.X("x", axis=None),
# #         y=alt.Y("y", axis=None),
# #         color=alt.Color("idx", legend=None, scale=alt.Scale()),
# #         size=alt.Size("rand", legend=None, scale=alt.Scale(range=[1, 150])),
# #     ))
