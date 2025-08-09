// New function to update card categories from selectedTagsList
async function updateCardCategoriesFromList(cardId, tagsList) {
    try {
        // Delete existing card-category relationships
        const { error: deleteError } = await supabase
            .from('card_categories')
            .delete()
            .eq('card_id', cardId);
        
        if (deleteError) {
            console.error('Error deleting old categories:', deleteError);
            // Don't throw - continue with adding new ones
        }
        
        // Add new categories if any
        if (tagsList && tagsList.length > 0) {
            const cardCategories = [];
            for (const tagName of tagsList) {
                // Get or create category
                const categoryId = await getOrCreateCategory(tagName);
                cardCategories.push({
                    card_id: cardId,
                    category_id: categoryId
                });
            }
            
            // Insert all card-category relationships
            const { error: insertError } = await supabase
                .from('card_categories')
                .insert(cardCategories);
            
            if (insertError) {
                console.error('Error adding new categories:', insertError);
                // Don't throw - the card was updated successfully
            }
        }
    } catch (error) {
        console.error('Error updating card categories:', error);
    }
}