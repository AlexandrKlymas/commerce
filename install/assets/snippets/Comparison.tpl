<?php
/**
 * Comparison
 * 
 * Comparison snippet, DocLister based
 *
 * @category    snippet
 * @version     0.1.0
 * @author      mnoskov
 * @internal    @modx_category Commerce
 * @internal    @installset base
*/

/**
 * [!Comparison
 *      &tvCategory=`10`
 *      &excludeTV=`category`
 *      &includeTV=`best`
 *      &checkBoundingList=`0`
 *      &categoryItemClass=`btn-secondary`
 *      &categoryActiveClass=`btn-primary`
 * !]
 */

if (empty($modx->commerce)) {
    return;
}

$items = array_map(function($item) {
    return $item['id'];
}, ci()->carts->getCart('comparison')->getItems());

if (empty($items)) {
    return;
}

$table   = $modx->getFullTablename('site_content');
$parents = $modx->db->getColumn('parent', $modx->db->select('parent', $table, "`id` IN (" . implode(',', $items) . ")"));
$parents = array_unique($parents);

$categoryParams = [];

foreach ($params as $key => $value) {
    if (strpos($key, 'category') === 0) {
        unset($params[$key]);
        $key = preg_replace('/^category/', '', $key);
        $key = lcfirst($key);
        $categoryParams[$key] = $value;
    }
}

if (isset($_GET['category']) && is_scalar($_GET['category']) && in_array($_GET['category'], $parents)) {
    $currentCategory = $_GET['category'];
}

if (empty($currentCategory)) {
    $currentCategory = reset($parents);
}

$categories = '';

if (count($parents) > 1) {
    $categoryParams = array_merge([
        'templatePath'      => 'assets/plugins/commerce/templates/front/',
        'templateExtension' => 'tpl',
        'tpl'               => '@FILE:comparison_category',
        'ownerTPL'          => '@FILE:comparison_categories',
        'itemClass'         => 'btn-secondary',
        'activeClass'       => 'btn-primary',
        'prepare'           => function($data, $modx, $DL, $eDL) {
            $data['class'] = $DL->getCFGDef('currentId') == $data['id'] ? $DL->getCFGDef('activeClass') : $DL->getCFGDef('itemClass');
            return $data;
        },
    ], $categoryParams, [
        'currentId' => $currentCategory,
        'idType'    => 'documents',
        'documents' => $parents,
        'sortType'  => 'doclist',
    ]);

    $categories = $modx->runSnippet('DocLister', $categoryParams);
}

$ids = $modx->db->getColumn('id', $modx->db->select('id', $table, "`parent` = '$currentCategory' AND `id` IN ('" . implode("','", $items) . "')"));

$params = array_merge([
    'templatePath'      => 'assets/plugins/commerce/templates/front/',
    'templateExtension' => 'tpl',
    'ownerTPL'          => '@FILE:comparison_table',
    'headerTpl'         => '@FILE:comparison_table_header_cell',
    'footerTpl'         => '@FILE:comparison_table_footer_cell',
    'keyTpl'            => '@FILE:comparison_table_key_cell',
    'valueTpl'          => '@FILE:comparison_table_value_cell',
    'rowTpl'            => '@FILE:comparison_table_row',
    'customLang'        => 'common,cart',
], $params, [
    'controller' => 'Comparison',
    'dir'        => 'assets/plugins/commerce/src/Controllers/',
    'idType'     => 'documents',
    'sortType'   => 'doclist',
    'documents'  => $ids,
    'category'   => $currentCategory,
    'rows'       => array_flip($items),
]);

$docs = $modx->runSnippet('DocLister', $params);

$modx->regClientScript('assets/plugins/commerce/js/comparison.js', [
    'version' => $modx->commerce->getVersion(),
]);

return $categories . $docs;
