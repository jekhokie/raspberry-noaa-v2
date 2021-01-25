      <nav aria-label="page" id="pagination" class="mb-0">
        <ul class="pagination pagination-sm justify-content-center mb-0 mx-2">
          <li class="page-item<?php if ($page <= 1) { echo " disabled"; } ?>">
            <a class="page-link" href="<?php echo "?page=" . ($page-1); ?>" aria-label="<?php echo $lang['prev']; ?>">
              <span aria-hiden="true">&laquo;</span>
              <span><?php echo $lang['prev']; ?></span>
            </a>
          </li>

          <li class="page-item<?php if ($page >= $page_count) { echo " disabled"; } ?>">
            <a class="page-link" href="<?php echo "?page=" . ($page+1); ?>" aria-label="<?php echo $lang['next']; ?>">
              <span><?php echo $lang['next']; ?></span>
              <span aria-hiden="true">&raquo;</span>
            </a>
          </li>
        </ul>
      </nav>
