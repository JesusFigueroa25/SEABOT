from fastapi import FastAPI
from app.database.database import Base, engine
from app.controllers import  user_controller,student_controller,diaryEntry_controller,emotionalRegister_controller,helpResource_controller,phqResult_controller,conversation_controller,message_controller,summary_controller,reports_controller

# Crear las tablas automáticamente en la BD
Base.metadata.create_all(bind=engine)

# Inicializar FastAPI
app = FastAPI(title="SeaBot API", version="1.0")

# Incluir routers (endpoints)
app.include_router(user_controller.router)
app.include_router(student_controller.router)

app.include_router(diaryEntry_controller.router)
app.include_router(emotionalRegister_controller.router)
app.include_router(helpResource_controller.router)
app.include_router(phqResult_controller.router)

app.include_router(conversation_controller.router)
app.include_router(message_controller.router)
app.include_router(summary_controller.router)

app.include_router(reports_controller.router)



