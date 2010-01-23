package org.purepdf.pdf
{
	import it.sephiroth.utils.HashMap;
	
	import org.purepdf.colors.CMYKColor;
	import org.purepdf.colors.ExtendedColor;
	import org.purepdf.colors.GrayColor;
	import org.purepdf.colors.RGBColor;
	import org.purepdf.elements.RectangleElement;
	import org.purepdf.errors.RuntimeError;
	import org.purepdf.utils.Bytes;

	public class PdfAnnotation extends PdfDictionary
	{
		public static const AA_BLUR: PdfName = PdfName.BL;
		public static const AA_DOWN: PdfName = PdfName.D;
		public static const AA_ENTER: PdfName = PdfName.E;
		public static const AA_EXIT: PdfName = PdfName.X;
		public static const AA_FOCUS: PdfName = PdfName.FO;
		public static const AA_JS_CHANGE: PdfName = PdfName.V;
		public static const AA_JS_FORMAT: PdfName = PdfName.F;
		public static const AA_JS_KEY: PdfName = PdfName.K;
		public static const AA_JS_OTHER_CHANGE: PdfName = PdfName.C;
		public static const AA_UP: PdfName = PdfName.U;
		public static const APPEARANCE_DOWN: PdfName = PdfName.D;
		public static const APPEARANCE_NORMAL: PdfName = PdfName.N;
		public static const APPEARANCE_ROLLOVER: PdfName = PdfName.R;
		public static const FLAGS_HIDDEN: int = 2;
		public static const FLAGS_INVISIBLE: int = 1;
		public static const FLAGS_LOCKED: int = 128;
		public static const FLAGS_NOROTATE: int = 16;
		public static const FLAGS_NOVIEW: int = 32;
		public static const FLAGS_NOZOOM: int = 8;
		public static const FLAGS_PRINT: int = 4;
		public static const FLAGS_READONLY: int = 64;
		public static const FLAGS_TOGGLENOVIEW: int = 256;
		public static const HIGHLIGHT_INVERT: PdfName = PdfName.I;
		public static const HIGHLIGHT_NONE: PdfName = PdfName.N;
		public static const HIGHLIGHT_OUTLINE: PdfName = PdfName.O;
		public static const HIGHLIGHT_PUSH: PdfName = PdfName.P;
		public static const HIGHLIGHT_TOGGLE: PdfName = PdfName.T;
		public static const MARKUP_HIGHLIGHT: int = 0;
		public static const MARKUP_SQUIGGLY: int = 3;
		public static const MARKUP_STRIKEOUT: int = 2;
		public static const MARKUP_UNDERLINE: int = 1;
		protected var _form: Boolean = false;
		protected var _placeInPage: int = -1;
		protected var _writer: PdfWriter;
		protected var reference: PdfIndirectReference;
		protected var used: Boolean = false;
		internal var _annotation: Boolean = true;
		internal var _templates: HashMap;

		public function PdfAnnotation( $writer: PdfWriter, rect: RectangleElement = null, action: PdfAction = null )
		{
			_writer = $writer;

			if ( rect != null )
			{
				if( action != null )
				{
					put( PdfName.SUBTYPE, PdfName.LINK );
					put( PdfName.RECT, PdfRectangle.createFromRectangle( rect ) );
					put( PdfName.A, action );
					put( PdfName.BORDER, new PdfBorderArray( 0, 0, 0 ) );
					put( PdfName.C, new PdfColor( 0x00, 0x00, 0xFF ) );
				} else {
					put( PdfName.RECT, PdfRectangle.createFromRectangle( rect ) );
				}
			}
		}

		public function get annotation(): Boolean
		{
			return _annotation;
		}

		public function set annotation( value: Boolean ): void
		{
			_annotation = value;
		}

		public function set borderStyle( border: PdfBorderDictionary ): void
		{
			put( PdfName.BS, border );
		}

		public function set defaultAppearanceString( cb: PdfContentByte ): void
		{
			var b: Bytes = cb.getInternalBuffer().toByteArray();
			var len: int = b.length;

			for ( var k: int = 0; k < len; ++k )
			{
				if ( b[k] == 10 )
					b[k] = 32;
			}
			put( PdfName.DA, new PdfString( b ) );
		}

		public function set flags( flags: int ): void
		{
			if ( flags == 0 )
				remove( PdfName.F );
			else
				put( PdfName.F, new PdfNumber( flags ) );
		}

		public function get form(): Boolean
		{
			return _form;
		}

		public function set form( value: Boolean ): void
		{
			_form = value;
		}

		/**
		 * Returns an indirect reference to the annotation
		 * @return the indirect reference
		 */
		public function getIndirectReference(): PdfIndirectReference
		{
			if ( reference == null )
			{
				reference = _writer.getPdfIndirectReference();
			}
			return reference;
		}

		public function get isAnnotation(): Boolean
		{
			return _annotation;
		}

		public function get isForm(): Boolean
		{
			return _form;
		}

		public function getUsed(): Boolean
		{
			return used;
		}

		public function setUsed(): void
		{
			used = true;
		}

		public function set mkBackgroundColor( color: RGBColor ): void
		{
			if ( color == null )
				mk.remove( PdfName.BG );
			else
				mk.put( PdfName.BG, getMKColor( color ) );
		}

		public function set mkBorderColor( color: RGBColor ): void
		{
			if ( color == null )
				mk.remove( PdfName.BC );
			else
				mk.put( PdfName.BC, getMKColor( color ) );
		}

		public function set mkRotation( value: int ): void
		{
			mk.put( PdfName.R, new PdfNumber( value ) );
		}

		public function get placeInPage(): int
		{
			return _placeInPage;
		}

		public function setAppearance( ap: PdfName, template: PdfTemplate ): void
		{
			var dic: PdfDictionary = getValue( PdfName.AP ) as PdfDictionary;

			if ( dic == null )
				dic = new PdfDictionary();
			dic.put( ap, template.indirectReference );
			put( PdfName.AP, dic );

			if ( !form )
				return;

			if ( templates == null )
				templates = new HashMap();
			templates.put( template, null );
		}

		public function get templates(): HashMap
		{
			return _templates;
		}

		public function set templates( value: HashMap ): void
		{
			_templates = value;
		}

		public function get writer(): PdfWriter
		{
			return _writer;
		}

		public function set writer( $writer: PdfWriter ): void
		{
			_writer = $writer;
		}

		protected function get mk(): PdfDictionary
		{
			var m: PdfDictionary = getValue( PdfName.MK ) as PdfDictionary;

			if ( m == null )
			{
				m = new PdfDictionary();
				put( PdfName.MK, m );
			}
			return m;
		}

		static public function createAction( writer: PdfWriter, llx: Number, lly: Number, urx: Number, ury: Number,
						action: PdfAction ): PdfAnnotation
		{
			var annot: PdfAnnotation = new PdfAnnotation( writer );
			annot.put( PdfName.SUBTYPE, PdfName.LINK );
			annot.put( PdfName.RECT, new PdfRectangle( llx, lly, urx, ury ) );
			annot.put( PdfName.A, action );
			annot.put( PdfName.BORDER, new PdfBorderArray( 0, 0, 0 ) );
			annot.put( PdfName.C, new PdfColor( 0x00, 0x00, 0xFF ) );
			return annot;
		}

		static public function createText( rect: RectangleElement, title: String, contents: String, opened: Boolean,
						icon: String ): PdfAnnotation
		{
			var annot: PdfAnnotation = new PdfAnnotation( null, rect );
			annot.put( PdfName.SUBTYPE, PdfName.TEXT );

			if ( title != null )
				annot.put( PdfName.T, new PdfString( title, PdfObject.TEXT_UNICODE ) );

			if ( contents != null )
				annot.put( PdfName.CONTENTS, new PdfString( contents, PdfObject.TEXT_UNICODE ) );

			if ( opened )
				annot.put( PdfName.OPEN, PdfBoolean.PDF_TRUE );

			if ( icon != null )
				annot.put( PdfName.NAME, new PdfName( icon ) );
			return annot;
		}

		static public function getMKColor( color: RGBColor ): PdfArray
		{
			var array: PdfArray = new PdfArray();
			var type: int = ExtendedColor.getType( color );

			switch ( type )
			{
				case ExtendedColor.TYPE_GRAY:
					array.add( new PdfNumber( GrayColor( color ).gray ) );
					break;
				case ExtendedColor.TYPE_CMYK:
					var cmyk: CMYKColor = CMYKColor( color );
					array.add( new PdfNumber( cmyk.cyan ) );
					array.add( new PdfNumber( cmyk.magenta ) );
					array.add( new PdfNumber( cmyk.yellow ) );
					array.add( new PdfNumber( cmyk.black ) );
					break;
				case ExtendedColor.TYPE_SEPARATION:
				case ExtendedColor.TYPE_PATTERN:
				case ExtendedColor.TYPE_SHADING:
					throw new RuntimeError( "separations patterns and shadings not.allowed in mk dictionary" );
					break;
				default:
					array.add( new PdfNumber( color.red / 255 ) );
					array.add( new PdfNumber( color.green / 255 ) );
					array.add( new PdfNumber( color.blue / 255 ) );
			}
			return array;
		}
	}
}