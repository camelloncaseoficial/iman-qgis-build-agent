/***************************************************************************
    imanpalette.cpp
    ---------------------
    IMAN Terra: cores da marca pela paleta do Qt (fatias 064, 065 e 066). Ver
    imanpalette.h.
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

bool ImanPalette::apply( const QString &uiTheme )
{
  // com um tema de fabrica escolhido pelo usuario, a paleta e a folha dele valem: nada muda
  if ( !isDefaultTheme( uiTheme ) )
    return false;

  // cores so da paleta da marca (iman_brand.h, gerado do brand.json): nenhum hex no C++
  const QColor highlight( IMAN_COLOR_BRAND_2 );
  const QColor highlightedText( IMAN_COLOR_PANEL );
  const QColor window( IMAN_COLOR_BG );
  const QColor button( IMAN_COLOR_PANEL_2 );
  QPalette palette = QApplication::palette();
  // fatia 064: o destaque, so nos grupos Active e Inactive
  for ( const QPalette::ColorGroup group : { QPalette::Active, QPalette::Inactive } )
  {
    palette.setColor( group, QPalette::Highlight, highlight );
    palette.setColor( group, QPalette::HighlightedText, highlightedText );
  }
  // fatia 065: o fundo das janelas, nos tres grupos (um painel desabilitado nao vira remendo de outra cor)
  // fatia 066: botoes e abas, nos tres grupos (a cor de fundo do botao nao indica estado; o desabilitado segue
  // indicado pelo texto)
  for ( const QPalette::ColorGroup group : { QPalette::Active, QPalette::Inactive, QPalette::Disabled } )
  {
    palette.setColor( group, QPalette::Window, window );
    palette.setColor( group, QPalette::Button, button );
  }
  QApplication::setPalette( palette );
  return true;
}
