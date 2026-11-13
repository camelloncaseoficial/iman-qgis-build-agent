/***************************************************************************
    imanpalette.h
    ---------------------
    IMAN Terra: as cores da marca pela paleta do Qt, sem folha de estilo
    (emendas de 2026-11-12 e de 2026-11-13 ao D-IMAN-040), uma mudanca por
    fatia: o destaque (item e texto selecionados) em verde IMAN (fatia 064,
    Highlight e HighlightedText, grupos Active e Inactive) e o fundo das
    janelas no cinza esverdeado IMAN (fatia 065, Window, grupos Active,
    Inactive e Disabled). Cores so da paleta da marca (IMAN_COLOR_*, do
    brand.json), e so quando o tema em uso e o default do QGIS.
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
     * Aplica as cores IMAN na paleta da aplicacao se \a uiTheme da o tema default, num unico setPalette: o destaque
     * (Highlight = brand-2, HighlightedText = panel; grupos Active e Inactive; o Disabled fica como o estilo o
     * entrega) e o fundo das janelas (Window = bg; grupos Active, Inactive e Disabled, porque fundo nao indica
     * estado). Os demais papeis ficam como o estilo os entrega. Chamar depois do QApplication::setStyle do arranque,
     * que repoe a paleta do estilo. Devolve se aplicou.
     */
    static bool apply( const QString &uiTheme );
};

#endif // IMANPALETTE_H
