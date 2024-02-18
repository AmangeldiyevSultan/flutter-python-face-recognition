import asyncio

import websockets
import json, io
import face_recognition

picture_of_me = face_recognition.load_image_file("me.png")
known_face_encoding = face_recognition.face_encodings(picture_of_me)

async def websocket_handler(websocket, path):
    try: 
        async for message in websocket:
            response = recognize_face(message)
            await websocket.send(json.dumps(response))
    except Exception as e:
        print("Websocket error: ", e) 

def recognize_face(message):
    try:
        unknown_picture = face_recognition.load_image_file(io.BytesIO(message))
        unknown_face_encodings = face_recognition.face_encodings(unknown_picture)

        if len(unknown_face_encodings) > 0:
            return {"status": "success", "message": "Face(s) found in the image", "data": len(unknown_face_encodings)}
        else:
            return {"status": "error", "message": "No face found in the image", "data": 0}
    except Exception as e:  
        return {"status": "error", "message": str(e)}
    

if __name__ == "__main__": 
    loop = asyncio.get_event_loop()
    loop.run_until_complete(
        websockets.serve(websocket_handler, '0.0.0.0', 8765)
    )
    loop.run_forever()
