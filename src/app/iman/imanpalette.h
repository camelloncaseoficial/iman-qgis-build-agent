/***************************************************************************
    imanpalette.h
    ---------------------
    IMAN Terra: o destaque (item selecionado, texto selecionado) em verde IMAN
    pela paleta do Qt, sem folha de estilo (fatia 064, emenda de 2026-11-13 ao
    D-IMAN-040). So os papeis Highlight e HighlightedText, nos grupos Active e
    Inactive, com as cores da paleta da marca (IMAN_COLOR_*, do brand.json), e
    so quando o tema em uso e o default do QGIS.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef IMANPALETTE_H
#define IMANPALETTE_H

#include "qgis_app.h"

#include <QString>

class APP_EXPORT ImanPalette
{
  public:
    /**
     * Verdadeiro quando \a uiTheme (o valor de UI/UITheme) da o tema default do QGIS: vazio, "default" ou um tema
     * que nao existe, a mesma regra do QgsApplication::setUITheme.
     */
    static bool isDefaultTheme( const QString &uiTheme );

    /**
     * Aplica o destaque IMAN na paleta da aplicacao (Highlight = brand-2, HighlightedText = panel; grupos Active e
     * Inactive; o Disabled fica como o estilo o entrega) se \a uiTheme da o tema default. Chamar depois do
     * QApplication::setStyle do arranque, que repoe a paleta do estilo. Devolve se aplicou.
     */
    static bool applyHighlight( const QString &uiTheme );
};

#endif // IMANPALETTE_H
