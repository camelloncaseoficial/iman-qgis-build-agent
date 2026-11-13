/***************************************************************************
    imanpalette.cpp
    ---------------------
    IMAN Terra: destaque IMAN pela paleta do Qt (fatia 064). Ver imanpalette.h.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "imanpalette.h"

#include "iman_brand.h"
#include "qgsapplication.h"

#include <QApplication>
#include <QColor>
#include <QPalette>

bool ImanPalette::isDefaultTheme( const QString &uiTheme )
{
  return uiTheme.isEmpty() || uiTheme == QLatin1String( "default" ) || !QgsApplication::uiThemes().contains( uiTheme );
}

bool ImanPalette::applyHighlight( const QString &uiTheme )
{
  // com um tema de fabrica escolhido pelo usuario, a paleta e a folha dele valem: nada muda
  if ( !isDefaultTheme( uiTheme ) )
    return false;

  // cores so da paleta da marca (iman_brand.h, gerado do brand.json): nenhum hex no C++
  const QColor highlight( IMAN_COLOR_BRAND_2 );
  const QColor highlightedText( IMAN_COLOR_PANEL );
  QPalette palette = QApplication::palette();
  for ( const QPalette::ColorGroup group : { QPalette::Active, QPalette::Inactive } )
  {
    palette.setColor( group, QPalette::Highlight, highlight );
    palette.setColor( group, QPalette::HighlightedText, highlightedText );
  }
  QApplication::setPalette( palette );
  return true;
}
