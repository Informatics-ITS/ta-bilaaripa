from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
from PIL import Image
import io
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="YOLO Image Classification API",
    description="API untuk klasifikasi gambar menggunakan YOLO model",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


try:
    model = YOLO("app/model/best.pt")
    logger.info("Model loaded successfully")
except Exception as e:
    logger.error(f"Failed to load model: {e}")
    model = None

@app.get("/")
async def root():
    return {
        "message": "YOLO Classification API is running",
        "status": "active",
        "endpoint": "/predict (POST)"
    }

# @app.get("/predict")
# async def predict_info():
#     """Info tentang endpoint predict"""
#     return {
#         "message": "Endpoint untuk prediksi gambar",
#         "method": "POST",
#         "content_type": "multipart/form-data",
#         "parameter": "file (image file)",
#         "example_curl": "curl -X POST http://127.0.0.1:8000/predict -F 'file=@image.jpg'"
#     }

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Endpoint untuk prediksi klasifikasi gambar
    
    Args:
        file: Image file (jpg, png, etc.)
    
    Returns:
        JSON response dengan hasil prediksi
    """

    if model is None:
        raise HTTPException(
            status_code=503, 
            detail="Model not available. Please check server logs."
        )
    
    if not file.content_type or not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400,
            detail="File harus berupa gambar (jpg, png, etc.)"
        )
    
    try:
        logger.info(f"Processing file: {file.filename}")
        
        contents = await file.read()
        
        if len(contents) == 0:
            raise HTTPException(
                status_code=400,
                detail="File gambar kosong"
            )
        
        try:
            image = Image.open(io.BytesIO(contents))

            if image.mode != 'RGB':
                image = image.convert('RGB')
        except Exception as img_error:
            logger.error(f"Image processing error: {img_error}")
            raise HTTPException(
                status_code=400,
                detail="Format gambar tidak valid atau rusak"
            )
        
        try:
            results = model(image, verbose=False)  
            logger.info("Prediction completed")
        except Exception as pred_error:
            logger.error(f"Prediction error: {pred_error}")
            raise HTTPException(
                status_code=500,
                detail="Gagal melakukan prediksi"
            )

        if not results or len(results) == 0:
            raise HTTPException(
                status_code=500,
                detail="Tidak ada hasil prediksi"
            )
        
        result = results[0]
        
        if hasattr(result, 'probs') and result.probs is not None:
            probs = result.probs
            class_id = int(probs.top1)
            confidence = float(probs.data[class_id])
            class_name = result.names[class_id] if result.names else f"class_{class_id}"
            
            response_data = {
                "success": True,
                "prediction": {
                    "class_id": class_id,
                    "class_name": class_name,
                    "confidence": round(confidence, 4)
                },
                "file_info": {
                    "filename": file.filename,
                    "size": len(contents)
                }
            }
            
        elif hasattr(result, 'boxes') and result.boxes is not None:
            boxes = result.boxes
            detections = []
            
            for box in boxes:
                detection = {
                    "class_id": int(box.cls[0]),
                    "class_name": result.names[int(box.cls[0])],
                    "confidence": round(float(box.conf[0]), 4),
                    "bbox": box.xyxy[0].tolist()  
                }
                detections.append(detection)
            
            response_data = {
                "success": True,
                "detections": detections,
                "total_objects": len(detections),
                "file_info": {
                    "filename": file.filename,
                    "size": len(contents)
                }
            }
        else:
            raise HTTPException(
                status_code=500,
                detail="Model tidak menghasilkan hasil yang diharapkan"
            )
        

        if 'prediction' in response_data:
            logger.info(f"Prediction successful: {response_data['prediction']}")
        else:
            detection_count = len(response_data.get("detections", []))
            logger.info(f"Detection successful: {detection_count} objects detected")

        return JSONResponse(
            content=response_data,
            status_code=200,
            headers={
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Global exception handler: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "Internal server error",
            "detail": str(exc)
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8000,
        log_level="info"
    )