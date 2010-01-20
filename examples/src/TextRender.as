package
{
	import flash.events.Event;
	
	import org.purepdf.Font;
	import org.purepdf.colors.RGBColor;
	import org.purepdf.elements.Chunk;
	import org.purepdf.elements.Paragraph;
	import org.purepdf.pdf.PdfContentByte;
	import org.purepdf.pdf.fonts.BaseFont;
	import org.purepdf.pdf.fonts.BuiltinFonts;
	import org.purepdf.pdf.fonts.FontsResourceFactory;

	public class TextRender extends DefaultBasicExample
	{
		[Embed(source="/Users/alessandro/Library/Fonts/CarolinaLTStd.otf", mimeType="application/octet-stream")] private var cls1: Class;
			
		public function TextRender()
		{
			super( null );
		}

		override protected function execute( event: Event = null ): void
		{
			super.execute();
			FontsResourceFactory.getInstance().registerFont("CarolinaLTStd.otf", cls1);
			
			createDocument();
			document.open();
			
			var bf: BaseFont = BaseFont.createFont("CarolinaLTStd.otf", BaseFont.CP1252, BaseFont.EMBEDDED );
			var font: Font = new Font( -1, 20, -1, null, bf );
			var newline: Chunk = new Chunk('\n', font );
			
			var chunk: Chunk = new Chunk( "Quick brown fox jumps over the lazy dog.", font );
			chunk.setTextRenderMode( PdfContentByte.TEXT_RENDER_MODE_FILL, 0, RGBColor.RED );
			document.add( Paragraph.fromChunk( chunk ) );
			chunk.setTextRenderMode( PdfContentByte.TEXT_RENDER_MODE_FILL_STROKE, 0.3, RGBColor.RED );
			document.add( Paragraph.fromChunk( chunk ) );
			chunk.setTextRenderMode( PdfContentByte.TEXT_RENDER_MODE_INVISIBLE, 0, RGBColor.GREEN );
			document.add( Paragraph.fromChunk( chunk ) );
			chunk.setTextRenderMode( PdfContentByte.TEXT_RENDER_MODE_STROKE, 0.3, RGBColor.BLUE );
			document.add( Paragraph.fromChunk( chunk ) );
			document.add( newline );
			var bold: Chunk = new Chunk( "This looks like Font.BOLD", font );
			bold.setTextRenderMode( PdfContentByte.TEXT_RENDER_MODE_FILL_STROKE, 0.5, null );
			document.add( bold );
			
			document.close();
			save();
		}
	}
}