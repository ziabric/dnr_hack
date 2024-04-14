from http.server import BaseHTTPRequestHandler, HTTPServer
import socketserver
from pydantic import BaseModel
import math 
import base64
from io import BytesIO
from PIL import Image
import numpy as np
import easyocr
import re
import json
import sys
import pandas as pd
from datetime import datetime
from model_text_clf import TextClassifier
from categories import categories_dict, unique_cats, num_cat_dict
from transformers import AutoTokenizer, AutoModel
from torch.utils.data import DataLoader, TensorDataset
import torch
import pickle
 


with open("data/logistic_model.pkl", "rb") as f:
    log_reg = pickle.load(f)

reader = easyocr.Reader(['ru'])
tokenizer = AutoTokenizer.from_pretrained("cointegrated/rubert-tiny")
model = AutoModel.from_pretrained("cointegrated/rubert-tiny")

class EchoHandler(BaseHTTPRequestHandler):
    reader = easyocr.Reader(['ru'])
    price = None
    

    text_clf = TextClassifier(unique_cats, categories_dict, log_reg, tokenizer, model)

    def prepare_price(self):
        excel_file = "prices/be64b74aff589ea0.xlsx"
        # Чтение файла Excel
        price = pd.read_excel(excel_file)
        price.columns = ['num', 'category', 'ism', 'price_region']
        price.drop(['num', 'ism'], axis=1, inplace=True)
        price = price[~price['price_region'].isna()]
        self.price = {x:y for x, y in zip(price.category, price.price_region)}

    def get_square_area(self, result_):
        areas = []
        for detection in result_:
            area = 0
            coords = detection[0]
            side_lengths = []
            for i in range(3):
                x1, y1 = coords[i]
                x2, y2 = coords[i + 1]
                area += x1 * y2 - y1 * x2
                
            areas.append(abs(area) / 2)
                
        return areas
 
 
    def read(self, path):
        result = reader.readtext(path)
        ans = []
        filtered_idxs = []
        price = None
        
        # формируем текст
        for idx, detection in enumerate(result):
            (coords, text, prob) = detection
            if (prob > 0.65) | (len(text) > 6):
                ans.append(text)
                filtered_idxs.append(idx)
    
        filtered_result = [result[i] for i in filtered_idxs]
    
        max_square_idx = np.argmax(self.get_square_area(filtered_result))
    
        probably_price = re.sub(r'[^\d]', '', filtered_result[max_square_idx][1])
    
        
        if (probably_price.isdigit()):
            price = int(probably_price)
        else:
            price = np.nan
        
        return " ".join(ans), price

    def read_image_base64(self, image_base64: str) -> np.ndarray:
        
        # декодирование изображения из формата base64
        image_data = base64.b64decode(image_base64)
        image = Image.open(BytesIO(image_data))
        # преобразование изображения в массив numpy
        img_array = np.array(image)
        return img_array
        

    def read_and_process_image(self, image: np.ndarray) -> str:
        
        # обработка изображения с помощью функции read
        result_text, price = self.read(image)
        return result_text, price
        

    def do_GET(self):
        # Ответить клиенту
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        
        # Возвращаем запрос клиенту как эхо
        self.wfile.write(f"GET request for {self.path}".encode())

    def do_POST(self):
        # try:
        # Читаем длину данных
        content_length = int(self.headers['Content-Length'])
        # Читаем данные (тело запроса)
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        data = json.loads(post_data)
        image = data['image_base64']
        image = self.read_image_base64(image)
        text, price = self.read_and_process_image(image)

        pred_category = self.text_clf.predict(text)
        pred_category = num_cat_dict[pred_category]

        # Ответить клиенту
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        
        # Отправляем прочитанные данные обратно клиенту
        print(text)

        if not self.price:
            self.prepare_price()

        # if price > self.price[pred_category]:

        df = pd.DataFrame(data={
                'Категория': [pred_category],
                'Цена': [price],
                # 'Цена в регионе': [self.price[pred_category]],
                'Дата': [datetime.now().date()]
            })

        try:
            past_price = pd.read_csv("data/report.csv")
            df = pd.concat([df, past_price])
        except:
            pass


        df.to_csv("data/report.csv", index=False)

        text = "Отчет отправлен!"
        self.wfile.write(text.encode('utf-8'))
        # except:
        #     text = "Ошибка на сервере"
        #     self.wfile.write(text.encode('utf-8'))

def run(server_class=HTTPServer, handler_class=EchoHandler, port=8000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting httpd on port {port}...")
    httpd.serve_forever()

if __name__ == "__main__":
    run()