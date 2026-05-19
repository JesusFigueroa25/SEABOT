import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

# 👉 Reemplaza con tu API KEY
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# 👉 Tu modelo fine-tuned
MODEL = os.getenv("FINE_TUNED_MODEL")

SYSTEM_PROMPT = """
Eres un acompañante emocional en español (no terapeuta).
Objetivo: brindar apoyo cálido y humano en las conversaciones.

Reglas:
- Nunca diagnostiques ni ofrezcas terapia clínica o recetas médicas.
- Usa un tono cercano, empático y natural (no formal ni robótico).
- Valida emociones y haz preguntas abiertas suaves para invitar a compartir.
- Evita pedir datos personales o prometer confidencialidad total.
- Español latino neutro, claro y sencillo.
- Si el mensaje del usuario contiene expresiones de suicidio o intención de hacerse daño, 
  clasifícalo en una escala de riesgo de 0 a 3 (0 = sin riesgo, 3 = riesgo alto). 
  Si el riesgo es 3, no continúes la conversación: responde de forma breve, empática y 
  ofrece los recursos oficiales en Perú (ejemplo: Línea 113 opción 5 del MINSA, 
  o acudir a la emergencia más cercana).
"""

def probar_modelo(mensaje_usuario):
    response = client.responses.create(
        model=MODEL,
        input=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": mensaje_usuario}
        ],
        temperature=0.8
    )

    # Obtener texto de respuesta
    output_text = response.output[0].content[0].text # type: ignore
    return output_text


# ===== PRUEBAS =====
if __name__ == "__main__":
    while True:
        user_input = input("\nTú: ")

        if user_input.lower() in ["salir", "exit"]:
            break

        respuesta = probar_modelo(user_input)
        print("\nBot:", respuesta)