import zipfile
import xml.etree.ElementTree as ET
import sys

def extract_text_from_docx(docx_path):
    try:
        with zipfile.ZipFile(docx_path) as z:
            xml_content = z.read('word/document.xml')
        
        tree = ET.fromstring(xml_content)
        
        # The namespace for Word XML
        namespace = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
        
        paragraphs = []
        for paragraph in tree.findall('.//w:p', namespace):
            texts = [node.text
                     for node in paragraph.findall('.//w:t', namespace)
                     if node.text]
            if texts:
                paragraphs.append(''.join(texts))
                
        return '\n'.join(paragraphs)
    except Exception as e:
        return f"Error reading {docx_path}: {e}"

if __name__ == '__main__':
    if len(sys.argv) > 1:
        for f in sys.argv[1:]:
            print(f"--- {f} ---")
            print(extract_text_from_docx(f))
            print("-----------------------")
