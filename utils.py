import os
import re
from lxml import etree
import pandas as pd


XPATH_SEPERATOR = "/"
ATTRIB_SEPERATOR = "@"
EXCLUDED_CHILDREN_TAGS = ["budget", "transaction"]


def xpath_sort(xpath_key):
    pattern = re.compile(r"\[(\d+)\]")
    xpath_hierarchy = len(xpath_key.split(XPATH_SEPERATOR))
    path_indexes = [int(found) for found in pattern.findall(xpath_key)]
    return xpath_hierarchy, path_indexes, xpath_key


def create_ancestor_tag(absolute_xpath):
    xpath_without_attribute = absolute_xpath.split(ATTRIB_SEPERATOR)[0]
    xpath_split = [elem_xpath.split("[")[0] for elem_xpath in xpath_without_attribute.split(XPATH_SEPERATOR)]
    if len(xpath_split) > 1:
        elem_tag = xpath_split[1]
        parent_tag = xpath_split[0]
        ancestor_tag = "{}{}{}".format(parent_tag, XPATH_SEPERATOR, elem_tag)
    else:
        ancestor_tag = xpath_without_attribute
    return ancestor_tag


def remove_xpath_index(relative_xpath):
    split_path = relative_xpath.split("[")
    indexless_path = "[".join(split_path[:-1])
    return indexless_path


def increment_xpath(absolute_xpath):
    split_path = absolute_xpath.split("[")
    indexless_path = "[".join(split_path[:-1])
    path_index = int(split_path[-1][:-1])
    path_index += 1
    incremented_xpath = "{}[{}]".format(indexless_path, path_index)
    return incremented_xpath


def recursive_tree_traversal(element, absolute_xpath, element_dictionary):
    # Main value
    element_value = str(element.text) if element.text else ""
    while absolute_xpath in element_dictionary:
        absolute_xpath = increment_xpath(absolute_xpath)

    element_dictionary[absolute_xpath] = element_value

    # Attribute values
    element_attributes = element.attrib
    for attrib_key in element_attributes.keys():
        attribute_xpath = ATTRIB_SEPERATOR.join([absolute_xpath, attrib_key])
        attribute_value = str(element_attributes[attrib_key]) if element_attributes[attrib_key] else ""
        element_dictionary[attribute_xpath] = attribute_value

    # Child values
    element_children = element.getchildren()
    if not element_children:
        return element_dictionary
    else:
        for child_elem in element_children:
            child_elem_tag = child_elem.tag
            if child_elem_tag not in EXCLUDED_CHILDREN_TAGS:
                child_absolute_xpath = XPATH_SEPERATOR.join([absolute_xpath, child_elem_tag]) + "[1]"
                element_dictionary = recursive_tree_traversal(child_elem, child_absolute_xpath, element_dictionary)

    return element_dictionary


def melt_iati(root):
    activities_list = []
    transactions_list = []
    budgets_list = []
    activities = root.getchildren()
    for activity in activities:
        activity_dict = recursive_tree_traversal(activity, "iati-activity", {})
        activities_list.append(activity_dict)

        transactions = activity.xpath("transaction")
        for transaction in transactions:
            transaction_dict = recursive_tree_traversal(transaction, "transaction", {})
            transaction_dict.update(activity_dict)
            transactions_list.append(transaction_dict)

        budgets = activity.xpath("budget")
        for budget in budgets:
            budget_dict = recursive_tree_traversal(budget, "budget", {})
            budget_dict.update(activity_dict)
            budgets_list.append(budget_dict)

    return (activities_list, transactions_list, budgets_list)


def xml_to_csv(xml_filename, csv_dir=None):
    if not csv_dir:
        csv_dir = os.path.splitext(xml_filename)[0]
    if not os.path.exists(csv_dir):
        os.makedirs(csv_dir)
    print("Converting IATI XML at '{}' to CSV in '{}'".format(xml_filename, csv_dir))

    a_filename = os.path.join(csv_dir, "activities.csv")
    t_filename = os.path.join(csv_dir, "transactions.csv")
    b_filename = os.path.join(csv_dir, "budgets.csv")

    with open(xml_filename, "r") as xmlfile:
        parser = etree.XMLParser(remove_blank_text=True)
        tree = etree.parse(xmlfile, parser=parser)

        root = tree.getroot()

        activities, transactions, budgets = melt_iati(root)
        a_df = pd.DataFrame(activities, dtype=str)
        a_df = a_df.sort_values('iati-activity/iati-identifier[1]')
        a_df.to_csv(a_filename, index=False)
        t_df = pd.DataFrame(transactions, dtype=str)
        t_df = t_df.sort_values('iati-activity/iati-identifier[1]')
        t_df.to_csv(t_filename, index=False)
        b_df = pd.DataFrame(budgets, dtype=str)
        b_df = b_df.sort_values('iati-activity/iati-identifier[1]')
        b_df.to_csv(b_filename, index=False)
