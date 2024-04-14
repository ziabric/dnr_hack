
import pymorphy2
 
from natasha import (
    Segmenter,
    MorphVocab,
    NewsNERTagger,
    NewsEmbedding,
    Doc
)
 
 
class TextClassifier:
    def __init__(self, unique_categories, encoded_categories, clf, tokenizer, emb_model):
        self._categories = unique_categories
        self._category_dict = {category: category.lower().split() for category in unique_categories}
        self.encoded_categories = encoded_categories
        self.clf = clf
        self.emb_model = emb_model
        self.tokenizer = tokenizer
        
        
        # Костыль
        for key, values in self._category_dict.items():
            if "крупа" in values:
                values.remove("крупа")
        self._category_dict[key] = values
        
        
        
    
    def _define_cat(self, text):
        tokens = text.split(' ')
        if 'мак' in tokens:
            return 'Макаронные изделия'
        
        for token in tokens:
            for key, values in self._category_dict.items():
                if token in values:
                    return key      
        return False
    
    
    def extract_weight(self, text):
        """
        Регулярное выражение возвращает кол-во и ед. измерения
        """
        text = text.lower()
        weight_pattern = r"(\d+(?:\,\d+)?)\s*(г|кг|мл|л)"
 
        match = re.search(weight_pattern, text)
        if match:
            weight = match.group(1)
            unit = match.group(2)
            return unit, weight
        else:
            return False, False
        
    
    
    def clean_text(self, text):
        """
        Чистит текст от шума (несуществующих слов и прочее), а также названий производителя (наверное). Текст передавать lower()
        """
        segmenter = Segmenter()
        emb = NewsEmbedding()
        ner_tagger = NewsNERTagger(emb)
        morph_vocab = MorphVocab()
        
        doc = Doc(text)
        doc.segment(segmenter)
        doc.tag_ner(ner_tagger)
        
        for span in doc.spans:
            span.normalize(morph_vocab)
            if span.type == 'ORG':
                text = text.replace(span.text, '')
        
        
        words = text.split()
        morph = pymorphy2.MorphAnalyzer()
        words = [word for word in words if morph.word_is_known(word)]
        
        pattern = r'[^\w\s]'
        text = ' '.join(words)
        cleaned_text = re.sub(pattern, '', text)
        
        return cleaned_text
        
        
    
    def predict(self, text):
        text = text.lower()
        prediction = self._define_cat(text)
        
        if (prediction != False):
            return self.encoded_categories[prediction]
        else:
            (unit, weight) = self.extract_weight(text)
            text = self.clean_text(text)
            
            inputs = self.tokenizer(text, return_tensors="pt")
            with torch.no_grad():
                model_output = self.emb_model(**{k: v for k, v in inputs.items()})
                
            embeddings = model_output.last_hidden_state[:, 0, :]
            embeddings = torch.nn.functional.normalize(embeddings)
            embeddings = embeddings.numpy()[0]
            prediction = self.clf.predict([embeddings])[0]
            
            
            return prediction