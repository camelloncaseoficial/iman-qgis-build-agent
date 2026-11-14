/***************************************************************************
    imanappstyle.cpp
    ---------------------
    IMAN Terra: o raio das quinas so do QPushButton (fatia 066). Ver
    imanappstyle.h.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "imanappstyle.h"

#include "iman_brand.h"
#include "imanpalette.h"

#include <QApplication>
#include <QImage>
#include <QLinearGradient>
#include <QPainter>
#include <QPixmap>
#include <QPushButton>
#include <QStyleOptionButton>

namespace
{
  // As cores do painel do botao do Fusion, de QFusionStylePrivate (qfusionstyle_p_p.h do Qt 5.15.13: outline, linhas
  // 113 a 117; highlightedOutline, 119 a 124; buttonColor, 132 a 138; innerContrastLine, 83 a 85), fora do macOS.

  QColor fusionOutline( const QPalette &palette )
  {
    if ( palette.window().style() == Qt::TexturePattern )
      return QColor( 0, 0, 0, 160 );
    return palette.window().color().darker( 140 );
  }

  QColor fusionHighlightedOutline( const QPalette &palette )
  {
    QColor outline = palette.color( QPalette::Highlight ).darker( 125 );
    if ( outline.value() > 160 )
      outline.setHsl( outline.hue(), outline.saturation(), 160 );
    return outline;
  }

  QColor fusionButtonColor( const QPalette &palette )
  {
    QColor color = palette.button().color();
    const int val = qGray( color.rgb() );
    color = color.lighter( 100 + qMax( 1, ( 180 - val ) / 6 ) );
    color.setHsv( color.hue(), static_cast<int>( color.saturation() * 0.75 ), color.value() );
    return color;
  }

  // O degrade de cima para baixo e a mistura de cores do qfusionstyle.cpp (qt_fusion_gradient e mergedColors): o
  // fonte do Qt nao esta na bancada; o desenho deste painel e conferido pixel a pixel com o do Fusion fora das quinas
  // (laudo 066), o que confere estas duas funcoes.
  QLinearGradient fusionGradient( const QRect &rect, const QColor &base )
  {
    const int x = rect.center().x();
    QLinearGradient gradient( x, rect.top(), x, rect.bottom() );
    gradient.setColorAt( 0, base.lighter( 124 ) );
    gradient.setColorAt( 1, base.lighter( 102 ) );
    return gradient;
  }

  QColor mergedColors( const QColor &a, const QColor &b, int factor )
  {
    const int maxFactor = 100;
    QColor merged = a;
    merged.setRed( ( a.red() * factor ) / maxFactor + ( b.red() * ( maxFactor - factor ) ) / maxFactor );
    merged.setGreen( ( a.green() * factor ) / maxFactor + ( b.green() * ( maxFactor - factor ) ) / maxFactor );
    merged.setBlue( ( a.blue() * factor ) / maxFactor + ( b.blue() * ( maxFactor - factor ) ) / maxFactor );
    return merged;
  }
} // namespace

ImanAppStyle::ImanAppStyle( const QString &base, const QString &uiTheme )
  : QgsAppStyle( base )
  , mUiTheme( uiTheme )
{
  // o raio da marca so com o tema default (como a paleta da marca) e sobre o fusion, cujo desenho este estilo repete
  const QStyle *baseStyle = QProxyStyle::baseStyle();
  mRoundPushButtons = ImanPalette::isDefaultTheme( uiTheme ) && baseStyle && baseStyle->inherits( "QFusionStyle" );
}

void ImanAppStyle::drawPrimitive( PrimitiveElement element, const QStyleOption *option, QPainter *painter, const QWidget *widget ) const
{
  if ( element == PE_PanelButtonCommand && mRoundPushButtons && qobject_cast<const QPushButton *>( widget ) )
  {
    const QStyleOptionButton *button = qstyleoption_cast<const QStyleOptionButton *>( option );
    const bool isDown = ( option->state & State_Sunken ) || ( option->state & State_On );
    const bool isFlat = button && ( button->features & QStyleOptionButton::Flat );
    // botao chato e solto: o Fusion nao desenha painel (so a borda do botao padrao); fica com ele
    if ( !isFlat || isDown )
    {
      drawPushButtonPanel( option, painter );
      return;
    }
  }
  QgsAppStyle::drawPrimitive( element, option, painter, widget );
}

void ImanAppStyle::drawPushButtonPanel( const QStyleOption *option, QPainter *painter ) const
{
  // o painel do botao do Fusion (PE_PanelButtonCommand), com o raio da marca no lugar do raio 2 do Fusion
  const qreal radius = static_cast<qreal>( IMAN_BUTTON_RADIUS_PX );
  const QStyleOptionButton *button = qstyleoption_cast<const QStyleOptionButton *>( option );
  const bool isDefault = button && ( button->features & QStyleOptionButton::DefaultButton ) && ( button->state & State_Enabled );
  const bool isDown = ( option->state & State_Sunken ) || ( option->state & State_On );
  const bool isEnabled = option->state & State_Enabled;
  const bool hasFocus = ( option->state & State_HasFocus ) && ( option->state & State_KeyboardFocusChange );
  const QColor highlightedOutline = fusionHighlightedOutline( option->palette );
  const QColor darkOutline = ( hasFocus || isDefault ) ? highlightedOutline : fusionOutline( option->palette );
  QColor buttonColor = fusionButtonColor( option->palette );
  if ( isDefault )
    buttonColor = mergedColors( buttonColor, highlightedOutline.lighter( 130 ), 90 );

  // como o Fusion (BEGIN_STYLE_PIXMAPCACHE e styleCacheImage, qstyle_p.h do Qt 5.15.13, linhas 77 a 83 e 93 a 120):
  // com transformacao simples, desenha numa imagem do tamanho do botao, na escala da aplicacao, e cola a imagem; a
  // mesma rasterizacao do Fusion, e por isso o mesmo pixel fora das quinas (sem guardar no cache de pixmaps, que e
  // dividido com o desenho do Fusion pela mesma chave)
  const int transform = painter->deviceTransform().type() | painter->worldTransform().type();
  const bool viaImage = !option->rect.isEmpty() && ( transform <= QTransform::TxTranslate || painter->deviceTransform().type() == QTransform::TxScale );
  QRect rect = option->rect;
  QImage image;
  QPainter imagePainter;
  QPainter *p = painter;
  if ( viaImage )
  {
    const qreal ratio = qApp->devicePixelRatio();
    image = QImage( option->rect.size() * ratio, QImage::Format_ARGB32_Premultiplied );
    image.setDevicePixelRatio( ratio );
    image.fill( 0 );
    imagePainter.begin( &image );
    p = &imagePainter;
    rect = QRect( 0, 0, option->rect.width(), option->rect.height() );
  }
  else
  {
    painter->save();
  }

  const QRect r = rect.adjusted( 0, 1, -1, 0 );
  p->setRenderHint( QPainter::Antialiasing, true );
  p->translate( 0.5, -0.5 );
  const QLinearGradient gradient = fusionGradient( rect, ( isEnabled && ( option->state & State_MouseOver ) ) ? buttonColor : buttonColor.darker( 104 ) );
  p->setPen( Qt::transparent );
  p->setBrush( isDown ? QBrush( buttonColor.darker( 110 ) ) : QBrush( gradient ) );
  p->drawRoundedRect( r, radius, radius );
  p->setBrush( Qt::NoBrush );
  // contorno
  p->setPen( !isEnabled ? QPen( darkOutline.lighter( 115 ) ) : QPen( darkOutline ) );
  p->drawRoundedRect( r, radius, radius );
  // linha de contraste de dentro (innerContrastLine)
  p->setPen( QColor( 255, 255, 255, 30 ) );
  p->drawRoundedRect( r.adjusted( 1, 1, -1, -1 ), radius, radius );

  if ( viaImage )
  {
    imagePainter.end();
    painter->drawPixmap( option->rect.topLeft(), QPixmap::fromImage( image ) );
  }
  else
  {
    painter->restore();
  }
}

QProxyStyle *ImanAppStyle::clone()
{
  return new ImanAppStyle( baseStyle(), mUiTheme );
}
