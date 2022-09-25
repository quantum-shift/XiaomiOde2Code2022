from datetime import datetime
from pathlib import Path
import random
from borb.pdf import Document
from borb.pdf import Page
from borb.pdf import SingleColumnLayout
from borb.pdf import Paragraph
from borb.pdf import PDF
from decimal import Decimal
from borb.pdf import Image
from borb.pdf import FixedColumnWidthTable as Table
from borb.pdf import Alignment
from borb.pdf import TableCell
from borb.pdf import HexColor, X11Color
from database.crud.product import get_product
from log_util.log_util import get_logger
from database import schemas

logger = get_logger('receipt.py')

def _build_invoice_information(order: schemas.Order):

    table_001 = Table(number_of_rows=5, number_of_columns=3)
	
    table_001.add(Paragraph("Bengaluru"))    
    table_001.add(Paragraph("Date", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT))    
    now = datetime.now()
    table_001.add(Paragraph("%d/%d/%d" % (now.day, now.month, now.year)))
	
    table_001.add(Paragraph("Karnataka"))    
    table_001.add(Paragraph("Receipt No.", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT))
    table_001.add(Paragraph("%d" % random.randint(1000, 10000)))   
	
    table_001.add(Paragraph("1800-103-6286"))    
    table_001.add(Paragraph("Order No.", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT))
    table_001.add(Paragraph("%d" % random.randint(1000, 10000)))   
	
    table_001.add(Paragraph("service.in@xiaomi.com"))    
    table_001.add(Paragraph(" "))
    table_001.add(Paragraph(" "))

    table_001.add(Paragraph("https://www.mi.com/in/"))
    table_001.add(Paragraph(" "))
    table_001.add(Paragraph(" "))

    table_001.set_padding_on_all_cells(Decimal(2), Decimal(2), Decimal(2), Decimal(2))    		
    table_001.no_borders()
    return table_001


def _build_itemized_description_table(order: schemas.Order):  
    table_001 = Table(number_of_rows=5+len(order.items), number_of_columns=4)  
    for h in ["DESCRIPTION", "QTY", "UNIT PRICE", "AMOUNT"]:  
        table_001.add(  
            TableCell(  
                Paragraph(h, font_color=X11Color("White"), horizontal_alignment=Alignment.CENTERED),  
                background_color=HexColor("FF6801"),  
            )  
        )
    

    odd_color = HexColor("#ffc69e")  
    even_color = HexColor("FFFFFF")  

    subtotal = 0

    for row_number, item in enumerate(order.items):  
        c = even_color if row_number % 2 == 0 else odd_color
        product: schemas.Product = get_product(product_id=item.product_id)
        subtotal += product['price']
        table_001.add(TableCell(Paragraph(product['name'], horizontal_alignment=Alignment.CENTERED), background_color=c))  
        table_001.add(TableCell(Paragraph(str(1), horizontal_alignment=Alignment.CENTERED), background_color=c))  
        table_001.add(TableCell(Paragraph("INR " + str(product['price']), horizontal_alignment=Alignment.CENTERED), background_color=c))  
        table_001.add(TableCell(Paragraph("INR " + str(product['price']), horizontal_alignment=Alignment.CENTERED), background_color=c))  
	  
    taxes = int(subtotal * 0.15)
    total = subtotal + taxes
    table_001.add(TableCell(Paragraph("Subtotal", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT,), col_span=3,))  
    table_001.add(TableCell(Paragraph(str(subtotal), horizontal_alignment=Alignment.RIGHT)))  
    table_001.add(TableCell(Paragraph("Discounts", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT,),col_span=3,))  
    table_001.add(TableCell(Paragraph("INR 0", horizontal_alignment=Alignment.RIGHT)))  
    table_001.add(TableCell(Paragraph("Taxes", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT), col_span=3,))  
    table_001.add(TableCell(Paragraph(str(taxes), horizontal_alignment=Alignment.RIGHT)))  
    table_001.add(TableCell(Paragraph("Total", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT  ), col_span=3,))  
    table_001.add(TableCell(Paragraph(str(total), horizontal_alignment=Alignment.RIGHT)))  
    table_001.set_padding_on_all_cells(Decimal(2), Decimal(2), Decimal(2), Decimal(2))
    table_001.no_borders()
    return table_001

def generate_receipt(order: schemas.Order):
    pdf: Document = Document()

    page = Page()
    pdf.add_page(page)


    page_layout = SingleColumnLayout(page)
    page_layout.vertical_margin = page.get_page_info().get_height() * Decimal(0.02)

    page_layout.add(
        Image(        
        Path("file:///../assets/mi.svg.png"),        
        width=Decimal(64),        
        height=Decimal(64),    
    ))

    page_layout.add(_build_invoice_information(order=order))
    
    page_layout.add(Paragraph(" "))

    page_layout.add(_build_itemized_description_table(order=order))
    
    page_layout.add(Paragraph(" "))
    
    with open(Path(f"receipt_{order.order_id}.pdf"), "wb") as pdf_file_handle:
        PDF.dumps(pdf_file_handle, pdf)
    
    logger.debug(f"Generated receipt for order id: {order.order_id}")

def delete_receipt(order_id: str):
    pdf_file_delete = Path(f"receipt_{order_id}.pdf")
    pdf_file_delete.unlink()
    logger.debug(f"Deleted generated receipt for order id: {order_id}")

def main():
    order = schemas.Order.construct()
    order.id = '12345'
    generate_receipt(order = order)

if __name__ == '__main__':
    main()
