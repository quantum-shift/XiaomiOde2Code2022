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

from database import schemas

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


def _build_itemized_description_table():  
    table_001 = Table(number_of_rows=15, number_of_columns=4)  
    for h in ["DESCRIPTION", "QTY", "UNIT PRICE", "AMOUNT"]:  
        table_001.add(  
            TableCell(  
                Paragraph(h, font_color=X11Color("White"), horizontal_alignment=Alignment.CENTERED),  
                background_color=HexColor("FF6801"),  
            )  
        )  
    

    # construct the Font object

    odd_color = HexColor("#ffc69e")  
    even_color = HexColor("FFFFFF")  
    for row_number, item in enumerate([("Redmi Note 9", 1, 20000), ("MI TV", 1, 30000), ("MI 11X", 1, 40000)]):  
        c = even_color if row_number % 2 == 0 else odd_color
        table_001.add(TableCell(Paragraph(item[0], horizontal_alignment=Alignment.CENTERED), background_color=c))  
        table_001.add(TableCell(Paragraph(str(item[1]), horizontal_alignment=Alignment.CENTERED), background_color=c))  
        table_001.add(TableCell(Paragraph("INR " + str(item[2]), horizontal_alignment=Alignment.CENTERED), background_color=c))  
        table_001.add(TableCell(Paragraph("INR " + str(item[1] * item[2]), horizontal_alignment=Alignment.CENTERED), background_color=c))  
	  
	# Optionally add some empty rows to have a fixed number of rows for styling purposes
    for row_number in range(3, 10):  
        c = even_color if row_number % 2 == 0 else odd_color  
        for _ in range(0, 4):
            table_001.add(TableCell(Paragraph(" "), background_color=c))
  
    table_001.add(TableCell(Paragraph("Subtotal", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT,), col_span=3,))  
    table_001.add(TableCell(Paragraph("INR 90000", horizontal_alignment=Alignment.RIGHT)))  
    table_001.add(TableCell(Paragraph("Discounts", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT,),col_span=3,))  
    table_001.add(TableCell(Paragraph("INR 0", horizontal_alignment=Alignment.RIGHT)))  
    table_001.add(TableCell(Paragraph("Taxes", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT), col_span=3,))  
    table_001.add(TableCell(Paragraph("INR 0", horizontal_alignment=Alignment.RIGHT)))  
    table_001.add(TableCell(Paragraph("Total", font="Helvetica-Bold", horizontal_alignment=Alignment.RIGHT  ), col_span=3,))  
    table_001.add(TableCell(Paragraph("INR 90000", horizontal_alignment=Alignment.RIGHT)))  
    table_001.set_padding_on_all_cells(Decimal(2), Decimal(2), Decimal(2), Decimal(2))
    table_001.no_borders()  
    return table_001

def generate_receipt(order: schemas.Order):
    # Create document
    pdf: Document = Document()

    # Add page
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

    page_layout.add(_build_itemized_description_table())
    
    page_layout.add(Paragraph(" "))
    
    with open(Path(f"receipt_{order.order_id}.pdf"), "wb") as pdf_file_handle:
        PDF.dumps(pdf_file_handle, pdf)

def main():
    order = schemas.Order.construct()
    order.id = '12345'
    generate_receipt(order = order)

if __name__ == '__main__':
    main()
