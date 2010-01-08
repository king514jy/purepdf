package
{
	import com.adobe.images.JPGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import org.purepdf.elements.images.ImageElement;
	import org.purepdf.pdf.PageSize;
	import org.purepdf.pdf.PdfDocument;
	import org.purepdf.pdf.PdfViewPreferences;
	import org.purepdf.pdf.PdfWriter;

	public class ViewerExample extends DefaultBasicExample
	{
		[Embed( source="assets/image1.jpg" )]
		private var cls1: Class;

		public function ViewerExample()
		{
			super();
		}
		
		override protected function createchildren() : void
		{
			create_default_button("HideWindowUI | FitWindow");
			
			var btn1: Sprite = createButton( 0xDDDDDD, "DisplayDocTitle | PageLayoutTwoPageLeft", execute1 );
			center( btn1, create_button );
			addChild( btn1 );
			
			var btn2: Sprite = createButton( 0xDDDDDD, "HideToolbar | PageModeUseThumbs", execute2 );
			center( btn2, btn1 );
			addChild( btn2 );
			
			description("This example show how you can customize PDF layout preferences");
		}
		
		protected function execute1( event: Event ): void
		{
			super.execute();
			_execute( PdfViewPreferences.DisplayDocTitle | PdfViewPreferences.PageLayoutTwoPageLeft, getQualifiedClassName( this ) + "_mode1" );
		}
		
		protected function execute2( event: Event ): void
		{
			super.execute();
			_execute( PdfViewPreferences.HideToolbar | PdfViewPreferences.PageModeUseThumbs, getQualifiedClassName( this ) + "_mode3" );
		}

		override protected function execute( event: Event=null ): void
		{
			super.execute();
			_execute( PdfViewPreferences.HideWindowUI | PdfViewPreferences.FitWindow, getQualifiedClassName( this ) + "_mode2" );
		}
		
		protected function _execute( mode: int, title: String ): void
		{
			var bmp: BitmapData = ( new cls1() as Bitmap ).bitmapData;
			
			createDocument("View preferences example");

			document.open();
			document.setViewerPreferences( mode );
			
			// JPEG image
			var bytes: ByteArray = new JPGEncoder( 90 ).encode( bmp );
			var image: ImageElement = ImageElement.getInstance( bytes );
			image.scalePercent( 50, 50 );
			document.addElement( image );
			
			// close and save the document
			document.close();
			save();
		}
	}
}