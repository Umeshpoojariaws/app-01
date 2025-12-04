from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Welcome to the AI UI Backend!"}

@app.get("/predict")
def predict():
    # Placeholder for AI model interaction
    return {"prediction": "This is a dummy AI prediction."}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
