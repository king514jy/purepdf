package org.purepdf.pdf
{
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.geom.Matrix;
	import org.purepdf.colors.CMYKColor;
	import org.purepdf.colors.ExtendedColor;
	import org.purepdf.colors.GrayColor;
	import org.purepdf.colors.RGBColor;
	import org.purepdf.colors.SpotColor;
	import org.purepdf.elements.AnnotationElement;
	import org.purepdf.elements.Element;
	import org.purepdf.elements.RectangleElement;
	import org.purepdf.elements.images.ImageElement;
	import org.purepdf.errors.NonImplementatioError;
	import org.purepdf.pdf.interfaces.IPdfOCG;
	import org.purepdf.utils.Bytes;
	import org.purepdf.utils.assertTrue;
	import org.purepdf.utils.pdf_core;

	public class PdfContentByte
	{
		public static const ALIGN_CENTER: int = Element.ALIGN_CENTER;
		public static const ALIGN_LEFT: int = Element.ALIGN_LEFT;
		public static const ALIGN_RIGHT: int = Element.ALIGN_RIGHT;
		public static const LINE_CAP_BUTT: int = 0;
		public static const LINE_CAP_PROJECTING_SQUARE: int = 2;
		public static const LINE_CAP_ROUND: int = 1;
		public static const LINE_JOIN_BEVEL: int = 2;
		public static const LINE_JOIN_MITER: int = 0;
		public static const LINE_JOIN_ROUND: int = 1;
		public static const TEXT_RENDER_MODE_CLIP: int = 7;
		public static const TEXT_RENDER_MODE_FILL: int = 0;
		public static const TEXT_RENDER_MODE_FILL_CLIP: int = 4;
		public static const TEXT_RENDER_MODE_FILL_STROKE: int = 2;
		public static const TEXT_RENDER_MODE_FILL_STROKE_CLIP: int = 6;
		public static const TEXT_RENDER_MODE_INVISIBLE: int = 3;
		public static const TEXT_RENDER_MODE_STROKE: int = 1;
		public static const TEXT_RENDER_MODE_STROKE_CLIP: int = 5;
		private static const unitRect: Vector.<Number> = Vector.<Number>( [ 0, 0, 0, 1, 1, 0, 1, 1 ] );
		protected var content: ByteBuffer = new ByteBuffer();
		protected var inText: Boolean = false;
		protected var layerDepth: Array;
		protected var mcDepth: int = 0;
		protected var pdf: PdfDocument;
		protected var state: GraphicState = new GraphicState();
		protected var stateList: Vector.<GraphicState> = new Vector.<GraphicState>();
		protected var writer: PdfWriter;

		public function PdfContentByte( $writer: PdfWriter )
		{
			writer = $writer;
			pdf = writer.pdfDocument;
		}

		/**
		 * Adds an <CODE>ImageElement</CODE> to the page. The <CODE>ImageElement</CODE> must have
		 * absolute positioning.
		 *
		 * @param image the <CODE>ImageElement</CODE> object
		 * @see org.purepdf.elements.images.ImageElement
		 */
		public function addImage( image: ImageElement ): void
		{
			addImage1( image, false );
		}

		/**
		 * Adds an <CODE>ImageElement</CODE> to the page. The <CODE>ImageElement</CODE> must have
		 * absolute positioning. The image can be placed inline.
		 * @param image the <CODE>ImageElement</CODE> object
		 * @param inlineImage <CODE>true</CODE> to place this image inline, <CODE>false</CODE> otherwise
		 *
		 * @see org.purepdf.elements.images.ImageElement
		 */
		public function addImage1( image: ImageElement, inlineImage: Boolean ): void
		{
			if ( !image.hasAbsoluteY )
				throw new Error( "image must have absolute position" );
			var matrix: Vector.<Number> = image.matrix;
			matrix[ ImageElement.CX ] = image.absoluteX - matrix[ ImageElement.CX ];
			matrix[ ImageElement.CY ] = image.absoluteY - matrix[ ImageElement.CY ];
			addImage2( image, matrix[ 0 ], matrix[ 1 ], matrix[ 2 ], matrix[ 3 ], matrix[ 4 ], matrix[ 5 ], inlineImage );
		}

		/**
		 * Adds an <CODE>ImageElement</CODE> to the page. The positioning of the <CODE>ImageElement</CODE>
		 * is done with the transformation matrix.
		 * To position an <CODE>ImageElement</CODE> at (x,y)
		 * use addImage(image, image_width, 0, 0, image_height, x, y)
		 *
		 * @param image the <CODE>ImageElement</CODE> object
		 * @param width
		 * @param b element of the transformation matrix
		 * @param c element of the transformation matrix
		 * @param height
		 * @param x
		 * @param y
		 * @param inlineImage
		 *
		 * @see org.purepdf.elements.images.ImageElement
		 */
		public function addImage2( image: ImageElement, width: Number, b: Number, c: Number, height: Number, x: Number, y: Number, inlineImage: Boolean ): void
		{
			if ( image.layer != null )
				beginLayer( image.layer );
			var h: Number;
			var w: Number;

			if ( image.isimgtemplate )
			{
				writer.addDirectImageSimple( image );
				var template: PdfTemplate = image.templateData;
				w = template.width;
				h = template.height;
				throw new NonImplementatioError();
					//addTemplate( template, a / w, b / w, c / h, d / h, e, f );
			}
			else
			{
				content.append( "q " );
				content.append_number( width ).append_char( ' ' );
				content.append_number( b ).append_char( ' ' );
				content.append_number( c ).append_char( ' ' );
				content.append_number( height ).append_char( ' ' );
				content.append_number( x ).append_char( ' ' );
				content.append_number( y ).append( " cm" );

				if ( inlineImage )
				{
					throw new NonImplementatioError();
				}
				else
				{
					var name: PdfName;
					var prs: PageResources = getPageResources();
					var maskImage: ImageElement = image.imageMask;

					if ( maskImage != null )
					{
						name = writer.addDirectImageSimple( maskImage );
						prs.addXObject( name, writer.getImageReference( name ) );
					}
					name = writer.addDirectImageSimple( image );
					name = prs.addXObject( name, writer.getImageReference( name ) );
					content.append_char( ' ' ).append_bytes( name.getBytes() ).append( " Do Q" ).append_separator();
				}
			}

			if ( image.hasBorders() )
			{
				saveState();
				w = image.getWidth();
				h = image.getHeight();
				concatCTM( width / w, b / w, c / h, height / h, x, y );
				rectangle( image );
				restoreState();
			}

			if ( image.layer != null )
				endLayer();
			var annot: AnnotationElement = image.annotation;

			if ( annot == null )
				return;
			var r: Vector.<Number> = new Vector.<Number>( unitRect.length );
			var k: int;

			for ( k = 0; k < unitRect.length; k += 2 )
			{
				r[ k ] = width * unitRect[ k ] + c * unitRect[ k + 1 ] + x;
				r[ k + 1 ] = b * unitRect[ k ] + height * unitRect[ k + 1 ] + y;
			}
			var llx: Number = r[ 0 ];
			var lly: Number = r[ 1 ];
			var urx: Number = llx;
			var ury: Number = lly;

			for ( k = 2; k < r.length; k += 2 )
			{
				llx = Math.min( llx, r[ k ] );
				lly = Math.min( lly, r[ k + 1 ] );
				urx = Math.max( urx, r[ k ] );
				ury = Math.max( ury, r[ k + 1 ] );
			}
			annot = new AnnotationElement( annot );
			annot.setDimensions( llx, lly, urx, ury );
			var an: PdfAnnotation = PdfAnnotationsImp.convertAnnotation( writer, annot, new RectangleElement( llx, lly, urx, ury ) );

			if ( an == null )
				return;
			throw new NonImplementatioError();
		}

		/**
		 * Adds an <CODE>ImageElement</CODE> to the page. The positioning of the <CODE>ImageElement</CODE>
		 * is done with the transformation matrix. To position an <CODE>ImageElement</CODE> at (x,y)
		 * use addImage(image, image_width, 0, 0, image_height, x, y).
		 *
		 * @param image the <CODE>ImageElement</CODE> object
		 * @param width
		 * @param b element of the transformation matrix
		 * @param c element of the transformation matrix
		 * @param height
		 * @param x
		 * @param y
		 *
		 * @see org.purepdf.elements.images.ImageElement
		 */
		public function addImage3( image: ImageElement, width: Number, b: Number, c: Number, height: Number, x: Number, y: Number ): void
		{
			addImage2( image, width, b, c, height, x, y, false );
		}

		/**
		 * Begins a graphic block whose visibility is controlled by the <CODE>layer</CODE>.
		 * Blocks can be nested. Each block must be terminated by an {@link #endLayer()}.<p>
		 * Note that nested layers with {@link PdfLayer#addChild(PdfLayer)} only require a single
		 * call to this method and a single call to {@link #endLayer()}; all the nesting control
		 * is built in.
		 * @param layer the layer
		 */
		public function beginLayer( layer: IPdfOCG ): void
		{
			throw new NonImplementatioError();
		}

		/**
		 * start writing text
		 */
		public function beginText(): void
		{
			if ( inText )
				throw new Error( "Unbalanced begin and end text" );
			inText = true;
			state.xTLM = 0;
			state.yTLM = 0;
			content.append( "BT" ).append_separator();
		}

		/** Draws a circle. The endpoint will (x+r, y).
		 *
		 * @param x x center of circle
		 * @param y y center of circle
		 * @param r radius of circle
		 */
		public function circle( x: Number, y: Number, r: Number ): void
		{
			var b: Number = 0.5523;
			moveTo( x + r, y );
			curveTo( x + r, y + r * b, x + r * b, y + r, x, y + r );
			curveTo( x - r * b, y + r, x - r, y + r * b, x - r, y );
			curveTo( x - r, y - r * b, x - r * b, y - r, x, y - r );
			curveTo( x + r * b, y - r, x + r, y - r * b, x + r, y );
		}

		/**
		 * Modify the current clipping path by intersecting it with the current path, using the
		 * <CODE>even_odd</CODE> winding number rule to determine which regions lie inside the clipping
		 * path.
		 */
		public function clip( even_odd: Boolean=false ): void
		{
			content.append( even_odd ? "W*" : "W" ).append_separator();
		}

		/**
		 * Closes the current subpath by appending a straight line segment from the current point
		 * to the starting point of the subpath.
		 */
		public function closePath(): void
		{
			content.append( "h" ).append_separator();
		}

		/**
		 * Closes the path, fills it using the <CODE>even_odd</CODE> winding number rule to determine the region to fill and strokes it.
		 */
		public function closePathFillStroke( even_odd: Boolean=false ): void
		{
			content.append( even_odd ? "b*" : "b" ).append_separator();
		}

		/**
		 * Closes the path and strokes it.
		 */
		public function closePathStroke(): void
		{
			content.append( "s" ).append_separator();
		}

		/**
		 * Concatenate a matrix to the current transformation matrix.
		 * @param a an element of the transformation matrix
		 * @param b an element of the transformation matrix
		 * @param c an element of the transformation matrix
		 * @param d an element of the transformation matrix
		 * @param e an element of the transformation matrix
		 * @param f an element of the transformation matrix
		 **/
		public function concatCTM( a: Number, b: Number, c: Number, d: Number, e: Number, f: Number ): void
		{
			content.append_number( a ).append( ' ' ).append_number( b ).append( ' ' ).append_number( c ).append( ' ' );
			content.append_number( d ).append( ' ' ).append_number( e ).append( ' ' ).append_number( f ).append( " cm" ).append_separator();
		}

		/**
		 * Appends a Bezier curve to the path, starting from the current point.
		 *
		 * @param       x1      x-coordinate of the first control point
		 * @param       y1      y-coordinate of the first control point
		 * @param       x2      x-coordinate of the second control point
		 * @param       y2      y-coordinate of the second control point
		 * @param       x3      x-coordinate of the ending point (= new current point)
		 * @param       y3      y-coordinate of the ending point (= new current point)
		 */
		public function curveTo( x1: Number, y1: Number, x2: Number, y2: Number, x3: Number, y3: Number ): void
		{
			content.append_number( x1 ).append_string( ' ' ).append_number( y1 ).append_string( ' ' ).append_number( x2 ).append_string( ' ' )
				.append_number( y2 ).append_string( ' ' ).append_number( x3 ).append_string( ' ' ).append_number( y3 ).append_string( " c" )
				.append_separator();
		}

		public function endLayer(): void
		{
			var n: int = 1;

			if ( layerDepth != null && !( layerDepth.length == 0 ) )
			{
				n = layerDepth[ ( layerDepth.length - 1 ) ];
				layerDepth.splice( layerDepth.length - 1, 1 );
			}
			else
			{
				throw new Error( "unbalanced layer operators" );
			}

			while ( n-- > 0 )
				content.append( "EMC" ).append_separator();
		}

		public function endText(): void
		{
			if ( !inText )
				throw new Error( "Unbalanced begin and end text" );
			inText = false;
			content.append( "ET" ).append_separator();
		}

		/**
		 * fill the path
		 *
		 * @param even_odd	Determine how to draw the path (using the <CODE>even-odd</CODE> winding rule or not. Default is false)
		 */
		public function fill( even_odd: Boolean=false ): void
		{
			content.append( even_odd ? "f*" : "f" ).append_separator();
		}

		/**
		 * Fills the path using the <CODE>even_odd</CODE> winding number rule to determine the region to fill and strokes it.
		 */
		public function fillStroke( even_odd: Boolean=false ): void
		{
			content.append( even_odd ? "B*" : "B" ).append_separator();
		}

		/**
		 * Return the internal buffer
		 *
		 */
		public function getInternalBuffer(): ByteBuffer
		{
			return content;
		}

		public function getPageResources(): PageResources
		{
			return pdf.getPageResources();
		}

		public function lineTo( x: Number, y: Number ): void
		{
			content.append_number( x ).append( ' ' ).append_number( y ).append( " l" ).append_separator();
		}

		/**
		 * Moves to the start of the next line, offset from the start of the current line.
		 *
		 * @param       x           x-coordinate of the new current point
		 * @param       y           y-coordinate of the new current point
		 */
		public function moveText( x: Number, y: Number ): void
		{
			state.xTLM += x;
			state.yTLM += y;
			content.append_number( x ).append_char( ' ' ).append_number( y ).append( " Td" ).append_separator();
		}

		public function moveTo( x: Number, y: Number ): void
		{
			content.append_number( x ).append_string( ' ' ).append_number( y ).append_string( " m" ).append_separator();
		}

		/**
		 * Ends the path without filling or stroking it.
		 */
		public function newPath(): void
		{
			content.append( "n" ).append_separator();
		}

		/**
		 * Adds a rectangle to the current path
		 * Either a RectangleElement or 4 Numbers are accepted as parameters
		 *
		 * @param       x       x-coordinate of the starting point
		 * @param       y       y-coordinate of the starting point
		 * @param       w       width
		 * @param       h       height
		 */
		public function rectangle( ... params: Array ): void
		{
			assertTrue( params != null && params.length > 0, 'ArgumentException' );

			if ( params[ 0 ] is RectangleElement )
			{
				pdf_core::setRectangle( params[ 0 ] );
			}
			else
			{
				var x: Number = params[ 0 ];
				var y: Number = params[ 1 ];
				var w: Number = params[ 2 ];
				var h: Number = params[ 3 ];
				content.append_number( x ).append_char( ' ' ).append_number( y ).append_char( ' ' ).append_number( w ).append_char( ' ' )
					.append_number( h ).append( " re" ).append_separator();
			}
		}

		/**
		 * Makes this <CODE>PdfContentByte</CODE> empty.
		 * Calls <code>reset( true )</code>
		 */
		public function reset( value: Boolean=true ): void
		{
			content.reset();

			if ( value )
				sanityCheck();
			state = new GraphicState();
		}

		public function resetFill(): void
		{
			content.append( "0 g" ).append_separator();
		}

		public function resetStroke(): void
		{
			content.append( "0 G" ).append_separator();
		}

		/**
		 * Restores the graphic state. <CODE>saveState</CODE> and
		 * <CODE>restoreState</CODE> must be balanced.
		 */
		public function restoreState(): void
		{
			content.append( "Q" ).append_separator();
			var idx: int = stateList.length - 1;

			if ( idx < 0 )
				throw new Error( 'IllegalPdfSyntaxException' );
			state = stateList[ idx ];
			stateList.splice( idx, 1 );
		}

		/**
		 * Saves the graphic state. <CODE>saveState</CODE> and
		 * <CODE>restoreState</CODE> must be balanced.
		 */
		public function saveState(): void
		{
			content.append( "q" ).append_separator();
			stateList.push( GraphicState.create( state ) );
		}

		/**
		 * Changes the current color for filling paths (device dependent colors!).
		 * <P>
		 * Sets the color space to <B>DeviceCMYK</B> (or the <B>DefaultCMYK</B> color space),
		 * and sets the color to use for filling paths.</P>
		 * <P>
		 * Following the PDF manual, each operand must be a number between 0 (no ink) and
		 * 1 (maximum ink).</P>
		 *
		 * @param   cyan    the intensity of cyan. A value between 0 and 1
		 * @param   magenta the intensity of magenta. A value between 0 and 1
		 * @param   yellow  the intensity of yellow. A value between 0 and 1
		 * @param   black   the intensity of black. A value between 0 and 1
		 */

		public function setCMYKFillColor( cyan: Number, magenta: Number, yellow: Number, black: Number ): void
		{
			helperCMYK( cyan, magenta, yellow, black );
			content.append_string( " k" ).append_separator();
		}

		/**
		 * Sets the fill color
		 * @param color the color
		 */
		public function setFillColor( color: RGBColor ): void
		{
			var type: int = ExtendedColor.getType( color );

			switch ( type )
			{
				case ExtendedColor.TYPE_GRAY:
					setGrayFill( GrayColor( color ).gray );
					break;

				case ExtendedColor.TYPE_CMYK:
					var cmyk: CMYKColor = CMYKColor( color );
					setCMYKFillColor( cmyk.cyan, cmyk.magenta, cmyk.yellow, cmyk.black );
					break;

				case ExtendedColor.TYPE_SEPARATION:
					var spot: SpotColor = SpotColor( color );
					setSpotFillColor( spot.pdfSpotColor, spot.tint );
					break;

				case ExtendedColor.TYPE_PATTERN:
					throw new NonImplementatioError();
					break;

				case ExtendedColor.TYPE_SHADING:
					throw new NonImplementatioError();
					break;

				default:
					setRGBColorFill( color.red, color.green, color.blue );
					break;
			}
		}

		/**
		 * Apply the graphic state
		 * @param gstate	The graphic state
		 */
		public function setGState( gstate: PdfGState ): void
		{
			var obj: Vector.<PdfObject> = writer.addSimpleExtGState( gstate );
			var prs: PageResources = getPageResources();
			var name: PdfName = prs.addExtGState( PdfName( obj[ 0 ] ), PdfIndirectReference( obj[ 1 ] ) );
			content.append_bytes( name.getBytes() ).append( " gs" ).append_separator();
		}

		public function setGrayFill( gray: Number ): void
		{
			content.append_number( gray ).append( " g" ).append_separator();
		}

		public function setGrayStroke( gray: Number ): void
		{
			content.append_number( gray ).append( " G" ).append_separator();
		}

		/**
		 * Changes the <VAR>Line cap style</VAR>.
		 * <P>
		 * The <VAR>line cap style</VAR> specifies the shape to be used at the end of open subpaths
		 * when they are stroked.<BR>
		 *
		 * @param	style
		 * @see	flash.display.CapsStyle
		 */
		public function setLineCap( value: String ): void
		{
			var style: int;

			switch ( value )
			{
				case CapsStyle.NONE:
					style = 0;
					break;
				case CapsStyle.ROUND:
					style = 1;
					break;
				default:
					style = 2;
					break;
			}

			if ( style >= 0 && style <= 2 )
				content.append( style ).append( " J" ).append_separator();
		}

		/**
		 * Changes the value of the line dash pattern.
		 */
		public function setLineDash( phase: Number ): void
		{
			content.append_string( "[] " ).append_number( phase ).append_string( " d" ).append_separator();
		}

		/**
		 * Changes the value of the line dash pattern.
		 * <P>
		 * The line dash pattern controls the pattern of dashes and gaps used to stroke paths.
		 *
		 * @param       phase       the value of the phase
		 * @param       unitsOn     the number of units that must be 'on' (equals the number of units that must be 'off').
		 */

		public function setLineDash2( unitsOn: Number, phase: Number ): void
		{
			content.append_string( "[" ).append_number( unitsOn ).append_string( "] " ).append_number( phase ).append_string( " d" )
				.append_separator();
		}

		/**
		 * Changes the value of the <VAR>line dash pattern</VAR>.
		 * <P>
		 * The line dash pattern controls the pattern of dashes and gaps used to stroke paths.
		 *
		 * @param       phase       the value of the phase
		 * @param       unitsOn     the number of units that must be 'on'
		 * @param       unitsOff    the number of units that must be 'off'
		 */

		public function setLineDash3( unitsOn: Number, unitsOff: Number, phase: Number ): void
		{
			content.append_string( "[" ).append_number( unitsOn ).append_char( ' ' ).append_number( unitsOff ).append_string( "] " )
				.append_number( phase ).append_string( " d" ).append_separator();
		}

		/**
		 * Changes the value of the <VAR>line dash pattern</VAR>.
		 * <P>
		 * The line dash pattern controls the pattern of dashes and gaps used to stroke paths.
		 * It is specified by an array and a phase. The array specifies the length
		 * of the alternating dashes and gaps. The phase specifies the distance into the dash
		 * pattern to start the dash.<BR>
		 *
		 * @param       array       length of the alternating dashes and gaps
		 * @param       phase       the value of the phase
		 */

		public function setLineDash4( array: Vector.<Number>, phase: Number ): void
		{
			content.append_string( "[" );

			for ( var i: int = 0; i < array.length; i++ )
			{
				content.append_number( array[ i ] );

				if ( i < array.length - 1 )
					content.append_char( ' ' );
			}
			content.append_string( "] " ).append_number( phase ).append_string( " d" ).append_separator();
		}

		/**
		 * Changes the Line join style.
		 * <P>
		 * The line join style specifies the shape to be used at the corners of paths
		 * that are stroked.<BR>
		 * Allowed values are JointStyle.MITER (Miter joins), JointStyle.ROUND (Round joins) and JointStyle.BEVEL (Bevel joins).<BR>
		 *
		 * @param joint
		 * @see	flash.diplay.JointStyle
		 */
		public function setLineJoin( joint: String ): void
		{
			var style: int;

			switch ( joint )
			{
				case JointStyle.BEVEL:
					style = 2;
					break;
				case JointStyle.MITER:
					style = 0;
					break;
				default:
					style = 1;
					break;
			}
			content.append( style ).append( " j" ).append_separator();
		}

		/**
		 * Changes the line width.
		 * <P>
		 * The line width specifies the thickness of the line used to stroke a path and is measured
		 * in user space units.<BR>
		 *
		 * @param	w
		 */
		public function setLineWidth( w: Number ): void
		{
			content.append_number( w ).append( " w" ).append_separator();
		}

		/**
		 * Output a String directly to the content
		 *
		 * @param value	The content to append
		 */
		public function setLiteral( value: String ): void
		{
			content.append_string( value );
		}

		/**
		 * Changes the Miter limit.
		 *
		 * @param miterLimit
		 */
		public function setMiterLimit( miterLimit: Number ): void
		{
			if ( miterLimit > 1 )
				content.append_number( miterLimit ).append( " M" ).append_separator();
		}

		/**
		 * Changes the current color for filling paths
		 * <P>
		 * Sets the color space to DeviceRGB
		 *
		 * @param red
		 * @param green
		 * @param blue
		 */
		public function setRGBColorFill( red: int, green: int, blue: int ): void
		{
			helperRGB( Number( red & 0xFF ) / 0xFF, Number( green & 0xFF ) / 0xFF, Number( blue & 0xFF ) / 0xFF );
			content.append( " rg" ).append_separator();
		}

		public function setRGBColorStroke( red: int, green: int, blue: int ): void
		{
			helperRGB( Number( red & 0xFF ) / 0xFF, Number( green & 0xFF ) / 0xFF, Number( blue & 0xFF ) / 0xFF );
			content.append( " RG" ).append_separator();
		}

		public function setRGBFillColor( red: int, green: int, blue: int ): void
		{
			helperRGB( Number( red & 0xFF ) / 0xFF, Number( green & 0xFF ) / 0xFF, Number( blue & 0xFF ) / 0xFF );
			content.append_string( " rg" ).append_separator();
		}

		/**
		 * Sets the fill color to a spot color.
		 *
		 * @param sp the spot color
		 * @param tint the tint for the spot color. ( 0 = no color, 1 = 100% color )
		 *
		 */
		public function setSpotFillColor( sp: PdfSpotColor, tint: Number ): void
		{
			checkWriter();
			state.colorDetails = writer.addSimple( sp );
			var prs: PageResources = getPageResources();
			var name: PdfName = state.colorDetails.colorName;
			name = prs.addColor( name, state.colorDetails.indirectReference );

			content.append_bytes( name.getBytes() ).append_string( " cs " ).append_number( tint ).append_string( " scn" ).append_separator();
		}

		public function setStrokeColor( color: RGBColor ): void
		{
			var type: int = ExtendedColor.getType( color );

			switch ( type )
			{
				case ExtendedColor.TYPE_GRAY:
					setGrayStroke( GrayColor( color ).gray );
					break;
				case ExtendedColor.TYPE_CMYK:
					throw new NonImplementatioError();
					break;
				case ExtendedColor.TYPE_SEPARATION:
					throw new NonImplementatioError();
					break;
				case ExtendedColor.TYPE_PATTERN:
					throw new NonImplementatioError();
					break;
				case ExtendedColor.TYPE_SHADING:
					throw new NonImplementatioError();
					break;
				default:
					setRGBColorStroke( color.red, color.green, color.blue );
					break;
			}
		}

		/**
		 * Concatenates the transformation to the current matrix
		 */
		public function setTransform( m: Matrix ): void
		{
			content.append_number( m.a ).append_char( ' ' ).append_number( m.b ).append_char( ' ' ).append_number( m.c ).append_char( ' ' );
			content.append_number( m.d ).append_char( ' ' ).append_number( m.tx ).append_char( ' ' ).append_number( m.ty ).append( " cm" )
				.append_separator();
		}

		public function size(): uint
		{
			return content.size();
		}

		/**
		 * Strokes the path.
		 */
		public function stroke(): void
		{
			content.append( "S" ).append_separator();
		}

		public function toString(): String
		{
			return content.toString();
		}

		/**
		 * Adds a variable width border to the current path.
		 * Only use if isUseVariableBorders = true
		 * @param rect a <CODE>RectangleElement</CODE>
		 */
		public function variableRectangle( rect: RectangleElement ): void
		{
			var t: Number = rect.getTop();
			var b: Number = rect.getBottom();
			var r: Number = rect.getRight();
			var l: Number = rect.getLeft();
			var wt: Number = rect.getBorderWidthTop();
			var wb: Number = rect.getBorderWidthBottom();
			var wr: Number = rect.getBorderWidthRight();
			var wl: Number = rect.getBorderWidthLeft();
			var ct: RGBColor = rect.getBorderColorTop();
			var cb: RGBColor = rect.getBorderColorBottom();
			var cr: RGBColor = rect.getBorderColorRight();
			var cl: RGBColor = rect.getBorderColorLeft();
			saveState();
			setLineCap( CapsStyle.NONE );
			setLineJoin( JointStyle.MITER );
			var clw: Number = 0;
			var cdef: Boolean = false;
			var ccol: RGBColor = null;
			var cdefi: Boolean = false;
			var cfil: RGBColor = null;
			var bt: Boolean, bb: Boolean;

			// draw top
			if ( wt > 0 )
			{
				setLineWidth( clw = wt );
				cdef = true;

				if ( ct == null )
					resetStroke();
				else
					setStrokeColor( ct );
				ccol = ct;
				moveTo( l, t - wt / 2 );
				lineTo( r, t - wt / 2 );
				stroke();
			}

			// Draw bottom
			if ( wb > 0 )
			{
				if ( wb != clw )
					setLineWidth( clw = wb );

				if ( !cdef || !compareColors( ccol, cb ) )
				{
					cdef = true;

					if ( cb == null )
						resetStroke();
					else
						setStrokeColor( cb );
					ccol = cb;
				}
				moveTo( r, b + wb / 2 );
				lineTo( l, b + wb / 2 );
				stroke();
			}

			// Draw right
			if ( wr > 0 )
			{
				if ( wr != clw )
					setLineWidth( clw = wr );

				if ( !cdef || !compareColors( ccol, cr ) )
				{
					cdef = true;

					if ( cr == null )
						resetStroke();
					else
						setStrokeColor( cr );
					ccol = cr;
				}
				bt = compareColors( ct, cr );
				bb = compareColors( cb, cr );
				moveTo( r - wr / 2, bt ? t : t - wt );
				lineTo( r - wr / 2, bb ? b : b + wb );
				stroke();

				if ( !bt || !bb )
				{
					cdefi = true;

					if ( cr == null )
						resetFill();
					else
						setFillColor( cr );
					cfil = cr;

					if ( !bt )
					{
						moveTo( r, t );
						lineTo( r, t - wt );
						lineTo( r - wr, t - wt );
						fill();
					}

					if ( !bb )
					{
						moveTo( r, b );
						lineTo( r, b + wb );
						lineTo( r - wr, b + wb );
						fill();
					}
				}
			}

			// Draw Left
			if ( wl > 0 )
			{
				if ( wl != clw )
					setLineWidth( wl );

				if ( !cdef || !compareColors( ccol, cl ) )
				{
					if ( cl == null )
						resetStroke();
					else
						setStrokeColor( cl );
				}
				bt = compareColors( ct, cl );
				bb = compareColors( cb, cl );
				moveTo( l + wl / 2, bt ? t : t - wt );
				lineTo( l + wl / 2, bb ? b : b + wb );
				stroke();

				if ( !bt || !bb )
				{
					if ( !cdefi || !compareColors( cfil, cl ) )
					{
						if ( cl == null )
							resetFill();
						else
							setFillColor( cl );
					}

					if ( !bt )
					{
						moveTo( l, t );
						lineTo( l, t - wt );
						lineTo( l + wl, t - wt );
						fill();
					}

					if ( !bb )
					{
						moveTo( l, b );
						lineTo( l, b + wb );
						lineTo( l + wl, b + wb );
						fill();
					}
				}
			}
			restoreState();
		}

		protected function checkWriter(): void
		{
			assertTrue( writer != null, "The writer is null" );
		}

		/**
		 * Checks for any error in mismatched save/restore state, begin/end text,
		 * begin/end layer, or begin/end marked content sequence.
		 */
		protected function sanityCheck(): void
		{
			if ( mcDepth != 0 )
			{
				throw Error( "unbalanced marked content operators" );
			}

			if ( inText )
			{
				throw new Error( "unbalanced begin and end text operators" );
			}

			if ( layerDepth != null && !( layerDepth.length == 0 ) )
			{
				throw new Error( "unbalanced layer operators" );
			}

			if ( !( stateList.length == 0 ) )
			{
				throw new Error( "unbalanced save and restore state operators" );
			}
		}

		pdf_core function setRectangle( rectangle: RectangleElement ): void
		{
			var x1: Number = rectangle.getLeft();
			var y1: Number = rectangle.getBottom();
			var x2: Number = rectangle.getRight();
			var y2: Number = rectangle.getTop();
			var background: RGBColor = rectangle.getBackgroundColor();

			if ( background != null )
			{
				saveState();
				setFillColor( background );
				this.rectangle( x1, y1, x2 - x1, y2 - y1 );
				fill();
				restoreState();
			}

			if ( !rectangle.hasBorders() )
				return;

			if ( rectangle.isUseVariableBorders() )
			{
				variableRectangle( rectangle );
			}
			else
			{
				if ( rectangle.getBorderWidth() != RectangleElement.UNDEFINED )
					setLineWidth( rectangle.getBorderWidth() );
				var color: RGBColor = rectangle.getBorderColor();

				if ( color != null )
					setStrokeColor( color );

				if ( rectangle.hasBorder( RectangleElement.BOX ) )
				{
					this.rectangle( x1, y1, x2 - x1, y2 - y1 );
				}
				else
				{
					if ( rectangle.hasBorder( RectangleElement.RIGHT ) )
					{
						moveTo( x2, y1 );
						lineTo( x2, y2 );
					}

					if ( rectangle.hasBorder( RectangleElement.LEFT ) )
					{
						moveTo( x1, y1 );
						lineTo( x1, y2 );
					}

					if ( rectangle.hasBorder( RectangleElement.BOTTOM ) )
					{
						moveTo( x1, y1 );
						lineTo( x2, y1 );
					}

					if ( rectangle.hasBorder( RectangleElement.TOP ) )
					{
						moveTo( x1, y2 );
						lineTo( x2, y2 );
					}
				}
				stroke();

				if ( color != null )
					resetStroke();
			}
		}

		private function compareColors( c1: RGBColor, c2: RGBColor ): Boolean
		{
			if ( c1 == null && c2 == null )
				return true;

			if ( c1 == null || c2 == null )
				return false;

			if ( c1 is ExtendedColor )
				return c1.equals( c2 );
			return c2.equals( c1 );
		}

		/**
		 * Helper to validate and write the CMYK color components.
		 */
		private function helperCMYK( cyan: Number, magenta: Number, yellow: Number, black: Number ): void
		{
			if ( cyan < 0 )
				cyan = 0.0;
			else if ( cyan > 1.0 )
				cyan = 1.0;

			if ( magenta < 0 )
				magenta = 0.0;
			else if ( magenta > 1.0 )
				magenta = 1.0;

			if ( yellow < 0 )
				yellow = 0.0;
			else if ( yellow > 1.0 )
				yellow = 1.0;

			if ( black < 0 )
				black = 0.0;
			else if ( black > 1.0 )
				black = 1.0;
			content.append_number( cyan ).append_char( ' ' ).append_number( magenta ).append_char( ' ' ).append_number( yellow ).append_char( ' ' )
				.append_number( black );
		}

		private function helperRGB( red: Number, green: Number, blue: Number ): void
		{
			if ( red < 0 )
				red = 0.0;
			else if ( red > 1.0 )
				red = 1.0;

			if ( green < 0 )
				green = 0.0;
			else if ( green > 1.0 )
				green = 1.0;

			if ( blue < 0 )
				blue = 0.0;
			else if ( blue > 1.0 )
				blue = 1.0;
			content.append_number( red ).append( ' ' ).append_number( green ).append( ' ' ).append_number( blue );
		}

		internal static function escapeByteArray( byte: Bytes ): Bytes
		{
			var content: ByteBuffer = new ByteBuffer();
			escapeString( byte, content );
			return content.toByteArray();
		}

		internal static function escapeString( byte: Bytes, content: ByteBuffer ): ByteBuffer
		{
			content.pdf_core::append_int( '('.charCodeAt( 0 ) );

			for ( var k: int = 0; k < byte.length; ++k )
			{
				var c: int = byte[ k ];

				switch ( String.fromCharCode( c ) )
				{
					case '\r':
						content.append( '\\r' );
						break;
					case '\n':
						content.append( '\\n' );
						break;
					case '\t':
						content.append( '\\t' );
						break;
					case '\b':
						content.append( '\\b' );
						break;
					case '\f':
						content.append( '\\f' );
						break;
					case '(':
					case ')':
					case '\\':
						content.pdf_core::append_int( '\\'.charCodeAt( 0 ) ).pdf_core::append_int( c );
						break;
					default:
						content.pdf_core::append_int( c );
						break;
				}
			}
			content.append( ')' );
			return content;
		}
	}
}