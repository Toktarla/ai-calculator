from fastapi import APIRouter, HTTPException
import base64
from io import BytesIO
from app.utils.utils import analyze_image
from app.schemas.image_data import ImageData
from PIL import Image

router = APIRouter()


@router.post('')
async def run(data: ImageData):
    try:
        image_data = base64.b64decode(data.image.split(",")[1])  # Assumes data:image/png;base64,<data>
        image_bytes = BytesIO(image_data)
        image = Image.open(image_bytes)
        responses = analyze_image(image, dict_of_vars=data.dict_of_vars)
        data = []
        for response in responses:
            data.append(response)
        print('response in route: ', response)
        return {"message": "Image processed", "data": data, "status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")
